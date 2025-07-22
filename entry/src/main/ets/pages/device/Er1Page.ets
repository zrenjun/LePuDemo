import { prompt, router } from '@kit.ArkUI';
import Er1Device from '@lepu/lepuhmble/src/main/ets/device/er1/Er1Device';
import { emitter } from '@kit.BasicServicesKit';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import LePuDevice from '@lepu/lepuhmble/src/main/ets/device/LePuDevice';
import Er1Config from '@lepu/lepuhmble/src/main/ets/device/er1/Er1Config';
import FileUtils from '@lepu/lepuhmble/src/main/ets/utils/FileUtils';
import FileDownloadState from '@lepu/lepuhmble/src/main/ets/device/FileDownloadState';
import Er1RtData from '@lepu/lepuhmble/src/main/ets/device/er1/Er1RtData';
import { ECGWaveform } from '../view/EcgRtWaveView';
import BleDevice from '@lepu/lepuhmble/src/main/ets/data/BleDevice';
import EcgFilter from '@lepu/lepuhmble/src/main/ets/utils/EcgFilter';


@Entry
@Component
struct Er1Page {
  private device: BleDevice | undefined = undefined;
  private sampling: string = "125";
  @State flag: boolean = true;
  @State files: string[] = [];
  @State fileStatus: FileDownloadState[] = [];
  @State deviceInfo: LePuDevice | undefined = undefined;
  @State deviceConfig: Er1Config | undefined = undefined;

  private getProgress(file: string): number {
    const status = this.fileStatus.find((item) => item.fileName === file);
    if (status == undefined || status.cancel) {
      return 0;
    }
    return status.offset * 100 / status.fileSize;
  }

  private toggleRealTimeData() {
    if (this.flag) {
      Er1Device.getInstance().getRealTimeData();
    } else {
      Er1Device.getInstance().stopRealTimeData();
    }
    this.flag = !this.flag;
  }

  build() {
    Column() {
      Text('设置时间')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          Er1Device.getInstance().setTime();
        })
      Text('获取设备信息')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          Er1Device.getInstance().getDeviceInfo();
        })
      if (this.deviceInfo) {
        Text(JSON.stringify(this.deviceInfo))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(100)
      }
      Text('获取配置')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          Er1Device.getInstance().getConfig();
        })
      if (this.deviceConfig) {
        Text(JSON.stringify(this.deviceConfig))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(80)
        Text("设置配置")
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(36)
          .onClick(() => {
            if (this.deviceConfig) {
              Er1Device.getInstance().setConfig(this.deviceConfig);
            }
          })
      }
      Text('恢复出厂设置')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          Er1Device.getInstance().resetFactory();
        })

      Text(this.flag ? '获取实时心电数据' : '停止获取实时心电数据')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          this.toggleRealTimeData();
        })

      if (!this.flag) {
        // 插入心电图组件
        ECGWaveform()
          .width('100%')
          .height(200)
      }

      Text('Usb下载文件')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          router.pushUrl({ url: 'pages/UsbFileCopyPage' });
        })

      Text('获取文件列表')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          Er1Device.getInstance().getFileList();
        })

      List() {
        ForEach(this.files, (fileName: string) => {
          ListItem() {
            Row() {
              Text(fileName)
                .fontSize($r('app.float.page_text_font_size'))
                .fontWeight(FontWeight.Bold)
                .margin({ left: 16 })
                .width('45%')

              if (this.getProgress(fileName) == 0) {
                Button('下载')
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    Er1Device.getInstance().getFileStart(fileName);
                  }).height(36)
              } else if (this.getProgress(fileName) == 100) {
                Button('查看')
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    this.ecgView(fileName);
                    // this.ecgView("R20240924145823");
                  })
                  .height(36)
              } else {
                Button('取消下载')
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    Er1Device.getInstance().getFileStop();
                  }).height(36)

                Text(`${this.getProgress(fileName).toFixed(2)}%`)
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .margin({ left: 16 })
              }
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)
          }
        }, (file: string) => file)
      }.width('100%')
      .layoutWeight(1)
      .margin(10)
      .divider({ color: Color.Gray, strokeWidth: 0.5 })

    }
    .height('100%')
    .width('100%')
  }

  private ecgView(fileName: string) {
    router.pushUrl({
      url: 'pages/EcgFileViewPage',
      params: {
        path: FileUtils.getFilesDirPath(`${getContext().filesDir}/er1`, `${fileName}.dat`),
        name: fileName.replace('R', ''), //去掉R 计算时间
        sampling: this.sampling
      }
    });
  }

  aboutToAppear() {
    this.device = BleDevice.copy((router.getParams() as Record<string, BleDevice>)['device']);


    //订阅事件
    emitter.on(Er1Device.EVENT_SET_TIME, () => {
      prompt.showToast({ message: "设置时间成功", duration: 300 });
    });

    emitter.on(Er1Device.EVENT_GET_INFO, (eventData: emitter.EventData) => {
      this.deviceInfo = eventData.data?.info;
    });


    emitter.on(Er1Device.EVENT_GET_FILE_LIST, (eventData: emitter.EventData) => {
      const files: string[] = eventData.data?.fileList;
      if (files.length > 0) {
        this.files = files;
      } else {
        prompt.showToast({ message: "无历史数据", duration: 300 });
      }
    });
    emitter.on(Er1Device.EVENT_FILE_PROGRESS, (eventData: emitter.EventData) => {
      const item: FileDownloadState = eventData.data?.fileStatus;
      const index = this.fileStatus.findIndex((file) => file.fileName === item.fileName);
      if (index !== -1) {
        // 创建新数组并替换旧对象
        const newFileStatus = this.fileStatus;
        newFileStatus[index] = item;
        this.fileStatus = newFileStatus;
      } else {
        this.fileStatus.push(item);
      }
    });
    emitter.on(Er1Device.EVENT_FILE_END, (eventData: emitter.EventData) => {
      BleLog.i(JSON.stringify(eventData.data?.path));
    });


    emitter.on(Er1Device.EVENT_RESET, () => {
      prompt.showToast({ message: "恢复出厂成功", duration: 300 });
    });
    emitter.on(Er1Device.EVENT_GET_CONFIG, (eventData: emitter.EventData) => {
      this.deviceConfig = eventData.data?.config;
    });
    emitter.on(Er1Device.EVENT_SET_CONFIG, () => {
      prompt.showToast({ message: "设置config成功", duration: 300 });
    });

    emitter.on(Er1Device.EVENT_GET_RT_DATA, (eventData: emitter.EventData) => {
      const receivedData: Er1RtData = eventData.data?.rtData;
      let dataFilter: number[] = [];
      receivedData.wave.wFs.forEach((value) => {
        const filter = EcgFilter.filter(value);
        if (filter.length > 0) {
          dataFilter = dataFilter.concat(filter)
        }
      })
      if (dataFilter.length > 0) { //128
        emitter.emit(ECGWaveform.EVENT_WAVE_DATA, { data: { wave: dataFilter } } )
      }
    });
  }

  aboutToDisappear() {
    // 取消事件。
    emitter.off(Er1Device.EVENT_SET_TIME);
    emitter.off(Er1Device.EVENT_GET_INFO);

    emitter.off(Er1Device.EVENT_GET_FILE_LIST);
    emitter.off(Er1Device.EVENT_FILE_PROGRESS);
    emitter.off(Er1Device.EVENT_FILE_END);
    emitter.off(Er1Device.EVENT_RESET);
    emitter.off(Er1Device.EVENT_GET_CONFIG);
    emitter.off(Er1Device.EVENT_SET_CONFIG);

    emitter.off(Er1Device.EVENT_GET_RT_DATA);

    Er1Device.getInstance().stopRealTimeData();
  }
}


