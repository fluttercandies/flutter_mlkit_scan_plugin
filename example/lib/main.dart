///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 11/25/20 1:32 PM
///
import 'dart:developer' as _developer;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mlkit_scan_plugin/mlkit_scan_plugin.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<Rect?> rectNotifier = ValueNotifier<Rect?>(null);
  final ValueNotifier<Widget?> scanViewNotifier = ValueNotifier<Widget?>(null);
  final ValueNotifier<ScanResultCallback?> listenerNotifier =
      ValueNotifier<ScanResultCallback?>(null);

  double get screenWidth => MediaQueryData.fromWindow(ui.window).size.width;

  double get screenHeight => MediaQueryData.fromWindow(ui.window).size.height;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    final bool isAllGranted = await checkAllPermissions();
    if (isAllGranted) {
      scanViewNotifier.value = ScanView(
        scanType: ScanType.wait,
        scanRect: Rect.fromLTWH(30, 100, screenWidth - 60, 300),
      );
    } else {
      showLackOfPermissionsDialog();
    }
  }

  void showLackOfPermissionsDialog() {
    _developer.log('请允许权限开启');
  }

  @override
  void dispose() {
    ScanPlugin.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Stack(
            children: <Widget>[
              ValueListenableBuilder<Widget?>(
                valueListenable: scanViewNotifier,
                builder: (_, Widget? scanView, __) =>
                    scanView ??
                    const Center(child: Text('Platform view not loaded')),
              ),
              ValueListenableBuilder<Rect?>(
                valueListenable: rectNotifier,
                builder: (_, Rect? rect, __) {
                  if (rect != null)
                    return Positioned.fromRect(
                      rect: rect,
                      child: ColoredBox(color: Colors.green.withOpacity(0.5)),
                    );
                  return const SizedBox.shrink();
                },
              ),
              Positioned.fill(
                child: ListView(
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        ScanPlugin.initializeScanning(
                          Rect.fromLTWH(30, 100, screenWidth - 60, 300),
                        );
                      },
                      child: const Text('loadScanView'),
                    ),
                    TextButton(
                      onPressed: () {
                        ScanPlugin.switchScanType(
                          ScanType.wait,
                          rect: null,
                        );
                      },
                      child: const Text('Make scanning idle.'),
                    ),
                    TextButton(
                      onPressed: () {
                        final Rect rect = Rect.fromLTWH(
                          30,
                          100,
                          screenWidth - 60,
                          300,
                        );
                        ScanPlugin.switchScanType(
                          ScanType.barcodeAndMobile,
                          rect: rect,
                        );
                        rectNotifier.value = rect;
                      },
                      child: const Text(
                        'Switch scan type to ScanType.barcodeAndMobile',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScanPlugin.reFocus(
                          Offset(screenWidth / 2, screenHeight / 2),
                        );
                      },
                      child: const Text('reFocus'),
                    ),
                    TextButton(
                      onPressed: () {
                        final Rect rect = Rect.fromLTWH(
                          30,
                          100,
                          screenWidth - 60,
                          100,
                        );
                        ScanPlugin.switchScanType(
                          ScanType.mobile,
                          rect: rect,
                        );
                        rectNotifier.value = rect;
                      },
                      child: const Text(
                        'Switch scan type to ScanType.mobile',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final Rect rect = Rect.fromLTWH(
                          30,
                          100,
                          screenWidth - 60,
                          100,
                        );
                        ScanPlugin.switchScanType(
                          ScanType.barcode,
                          rect: rect,
                        );
                        rectNotifier.value = rect;
                      },
                      child: const Text(
                        'Switch scan type to ScanType.barcode',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final Rect rect = Rect.fromLTWH(
                          30,
                          100,
                          screenWidth - 60,
                          screenWidth - 60,
                        );
                        ScanPlugin.switchScanType(
                          ScanType.qrCode,
                          rect: rect,
                        );
                        rectNotifier.value = rect;
                      },
                      child: const Text(
                        'Switch scan type to ScanType.qrCode',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScanPlugin.destroy();
                        ScanPlugin.stopScan();
                      },
                      child: const Text('Stop scan.'),
                    ),
                    _buildAnalyzingImageFileButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (listenerNotifier.value != null) {
              ScanPlugin.removeListener(listenerNotifier.value!);
              listenerNotifier.value = null;
            } else {
              void listener(ScanResult result) {
                print(result);
              }

              listenerNotifier.value = listener;
              ScanPlugin.addListener(listener);
            }
          },
          child: ValueListenableBuilder<ScanResultCallback?>(
            valueListenable: listenerNotifier,
            builder: (_, ScanResultCallback? listener, __) {
              if (listener == null) {
                return const Icon(Icons.remove);
              }
              return const Icon(Icons.add);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingImageFileButton() {
    return Builder(builder: (BuildContext context) {
      return TextButton(
        onPressed: () async {
          final ImagePicker imagePicker = ImagePicker();
          final XFile? file = await imagePicker.pickImage(
            source: ImageSource.gallery,
          );
          if (file != null) {
            final List<Barcode> result =
                await ScanPlugin.analyzingImageFile(file.path);
            showBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return result.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        child: const Text('Nothing'),
                      )
                    : Container(
                        padding: const EdgeInsets.all(24.0),
                        height:
                            MediaQueryData.fromWindow(window).size.height / 2,
                        child: ListView.builder(
                          itemCount: result.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Barcode code = result[index];
                            final ui.Rect? box = code.boundingBox;
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              margin: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    code.value,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(),
                                  if (box != null)
                                    Text(
                                      'boundingBox: top(${box.top}), '
                                      'right(${box.right}), '
                                      'bottom(${box.bottom}), '
                                      'left(${box.left})',
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
              },
            );
          }
        },
        child: const Text('Analyzing image file.'),
      );
    });
  }

  Future<bool> checkAllPermissions() {
    return checkPermissions(<Permission>[
      Permission.camera,
      Permission.storage,
    ]);
  }

  Future<bool> checkPermissions(List<Permission> permissions) async {
    try {
      final Map<Permission, PermissionStatus> status =
          await permissions.request();
      status.forEach((Permission key, PermissionStatus value) {
        _developer.log('$key: $value');
      });
      return !status.values.any(
        (PermissionStatus p) => p != PermissionStatus.granted,
      );
    } catch (e) {
      _developer.log('Error when requesting permission: $e');
      return false;
    }
  }
}
