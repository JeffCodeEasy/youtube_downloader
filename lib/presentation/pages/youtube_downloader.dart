import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class YoutubeDownloader extends StatefulWidget {
  const YoutubeDownloader({super.key});

  @override
  YoutubeDownloaderState createState() => YoutubeDownloaderState();
}

class YoutubeDownloaderState extends State<YoutubeDownloader> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // if (await Permission.storage.isDenied) {
      //   var status = await Permission.storage.request();
      //   if (!status.isGranted) {
      //     setState(() {
      //       _message = 'Permiso de almacenamiento denegado';
      //     });
      //     return;
      //   }
      // }

      // Si es Android 11 o superior, solicita el permiso de "gestión de almacenamiento"
      if (await Permission.manageExternalStorage.isDenied) {
        var manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          setState(() {
            _message = 'Permiso de gestión de almacenamiento denegado';
          });
          return;
        }
      }
    }
  }

  Future<void> downloadVideo(String videoUrl) async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await requestStoragePermission();

      var yt = YoutubeExplode();
      var video = await yt.videos.get(videoUrl);
      var manifest = await yt.videos.streamsClient.getManifest(videoUrl);
      var streamInfo = manifest.muxed.bestQuality;

      var dir = await getTemporaryDirectory();
      var savePath = '${dir.path}/${video.title}.mp4';

      var stream = yt.videos.streamsClient.get(streamInfo);
      var file = File(savePath);
      var output = file.openWrite();

      await stream.pipe(output);
      await output.flush();
      await output.close();

      setState(() {
        _message = 'Video descargado exitosamente.';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> downloadAudioToInternalStorage(String videoUrl) async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await requestStoragePermission();

      var yt = YoutubeExplode();
      var video = await yt.videos.get(videoUrl);
      var manifest = await yt.videos.streamsClient.getManifest(videoUrl);
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      // Obtener el almacenamiento interno
      var internalDir = await getExternalStorageDirectory();
      var savePath = path.join(internalDir!.path, '${video.title}.mp3');

      var audioStream = yt.videos.streamsClient.get(audioStreamInfo);
      var file = File(savePath);
      var output = file.openWrite();

      await audioStream.pipe(output);
      await output.flush();
      await output.close();

      setState(() {
        _message = 'Audio descargado exitosamente en: $savePath';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 150,
                  width: 150,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: AssetImage(
                            "assets/images/youtube.jpeg",
                          ),
                          fit: BoxFit.cover)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'URL de Video Youtube',
                    labelStyle: const TextStyle(color: Colors.red),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  cursorColor: Colors.red,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => downloadVideo(_urlController.text),
                            child: const Text(
                              'Descargar Video',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => downloadAudioToInternalStorage(
                                _urlController.text),
                            child: const Text(
                              'Descargar Audio',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                Text(
                  _message,
                  style: TextStyle(
                    color:
                        _message.contains('Error') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
