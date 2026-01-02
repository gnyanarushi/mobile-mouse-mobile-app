import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

/// Manages UDP reception for fragmented JPEG screen frames from the desktop server.
/// Packet format:
/// - Header (13 bytes): magic (4), version (1), frameSeq (4), totalFragments (2), fragmentIndex (2)
/// - Payload: JPEG fragment data
class UdpService {
  RawDatagramSocket? _socket;
  final Map<int, _FragmentedFrame> _frames = {};
  final _frameController = StreamController<Uint8List>.broadcast();
  Timer? _cleanupTimer;

  static const int _magic = 0x4D535452; // 'MSTR' in hex
  static const int _headerSize = 13;
  static const Duration _frameTimeout = Duration(seconds: 2);

  /// Stream of complete JPEG frames (ready to decode and display)
  Stream<Uint8List> get frameStream => _frameController.stream;

  bool get isListening => _socket != null;

  /// Start listening for UDP frames on the specified port
  Future<bool> startListening(int port) async {
    if (_socket != null) {
      dev.log('UDP already listening on port');
      return false;
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      dev.log('UDP listening on port $port');

      _socket!.listen(
        _onSocketEvent,
        onError: (e) {
          dev.log('UDP socket error: $e');
        },
        onDone: () {
          dev.log('UDP socket closed');
        },
      );

      // Start periodic cleanup of stale frames
      _cleanupTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _cleanupStaleFrames();
      });

      return true;
    } catch (e) {
      dev.log('Failed to bind UDP socket on port $port: $e');
      return false;
    }
  }

  void _onSocketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket?.receive();
      if (datagram == null) return;

      _processPacket(datagram.data);
    }
  }

  void _processPacket(Uint8List data) {
    if (data.length < _headerSize) {
      return; // Packet too small
    }

    final header = ByteData.sublistView(data, 0, _headerSize);
    final magic = header.getUint32(0, Endian.big);

    if (magic != _magic) {
      return; // Invalid magic number
    }

    // Version field reserved for future use
    // final version = header.getUint8(4);
    final frameSeq = header.getUint32(5, Endian.big);
    final totalFragments = header.getUint16(9, Endian.big);
    final fragmentIndex = header.getUint16(11, Endian.big);

    final payload = data.sublist(_headerSize);

    // Get or create frame buffer
    final frame = _frames.putIfAbsent(
      frameSeq,
      () => _FragmentedFrame(totalFragments),
    );

    // Store fragment if valid and not already received
    if (fragmentIndex < frame.parts.length &&
        frame.parts[fragmentIndex] == null) {
      frame.parts[fragmentIndex] = Uint8List.fromList(payload);
      frame.received++;
      frame.lastUpdate = DateTime.now();
    }

    // Check if frame is complete
    if (frame.received == frame.parts.length) {
      final jpeg = _assembleFrame(frame);
      _frameController.add(jpeg);
      _frames.remove(frameSeq);
    }
  }

  Uint8List _assembleFrame(_FragmentedFrame frame) {
    final builder = BytesBuilder(copy: false);
    for (var part in frame.parts) {
      if (part != null) {
        builder.add(part);
      }
    }
    return builder.toBytes();
  }

  void _cleanupStaleFrames() {
    final now = DateTime.now();
    _frames.removeWhere((seq, frame) {
      final isStale = now.difference(frame.lastUpdate) > _frameTimeout;
      if (isStale) {
        dev.log(
          'Dropping incomplete frame $seq (${frame.received}/${frame.parts.length} fragments)',
        );
      }
      return isStale;
    });
  }

  /// Stop listening and cleanup resources
  void stop() {
    _socket?.close();
    _socket = null;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _frames.clear();
    dev.log('UDP service stopped');
  }

  void dispose() {
    stop();
    _frameController.close();
  }
}

class _FragmentedFrame {
  final int total;
  final List<Uint8List?> parts;
  int received = 0;
  DateTime lastUpdate = DateTime.now();

  _FragmentedFrame(this.total) : parts = List<Uint8List?>.filled(total, null);
}
