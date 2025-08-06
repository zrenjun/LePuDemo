import { prompt, router } from '@kit.ArkUI';
import O2Device from '@lepu/lepuhmble/src/main/ets/device/o2/O2Device';
import { emitter } from '@kit.BasicServicesKit';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import FileUtils from '@lepu/lepuhmble/src/main/ets/utils/FileUtils';
import FileTransmit from '@lepu/lepuhmble/src/main/ets/device/FileTransmit';
import O2Info from '@lepu/lepuhmble/src/main/ets/device/o2/O2Info';
import O2Config from '@lepu/lepuhmble/src/main/ets/device/o2/O2Config';
import O2RtParam from '@lepu/lepuhmble/src/main/ets/device/o2/O2RtParam';
import BleDevice from '@lepu/lepuhmble/src/main/ets/data/BleDevice';


@Entry
@Component
struct O2Page {
  private device: BleDevice | undefined = undefined;
  @State flag: boolean = true;
  @State files: string[] = [];
  @State fileTransmit: FileTransmit[] = [];
  @State deviceInfo: O2Info | undefined = undefined;
  @State currentSpo2: O2RtParam | undefined = undefined;

  private getProgress(file: string): number {
    const status = this.fileTransmit.find((item) => item.fileName === file);
    if (status == undefined || status.cancel) {
      return 0;
    }
    return status.offset * 100 / status.fileSize;
  }

  private toggleRealTimeData() {
    if (this.flag) {
      O2Device.getInstance().getRealTimeParam();
    } else {
      O2Device.getInstance().stopRealTimeParam();
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
          O2Device.getInstance().setTime();
        })
      Text('设置血氧阈值')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          O2Device.getInstance().setSetOtherConfig(O2Config.SYNC_TYPE_OXI_THR, 90);
        })
      Text('获取设备信息')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          O2Device.getInstance().getDeviceInfo();
        })

      if (this.deviceInfo) {
        Text(JSON.stringify(this.deviceInfo.infoStr))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(250)
          .padding(20)
      }

      Text('恢复出厂设置')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          O2Device.getInstance().resetFactory();
        })

      Text(this.flag ? '获取实时数据' : '停止获取实时数据')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          this.toggleRealTimeData();
        })
      if (!this.flag && this.currentSpo2) {
        Column() {
          Text(`当前血氧: ${this.currentSpo2?.spo2}%`)
            .fontSize('app.float.page_text_font_size')
          Text(`当前脉率: ${this.currentSpo2?.pr}`)
            .fontSize('app.float.page_text_font_size')
          Text(`当前灌注指数: ${(this.currentSpo2?.pi ?? 0) / 10}`)
            .fontSize('app.float.page_text_font_size')
        }
        .padding(20)
      }

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
                    O2Device.getInstance().getFileStart(fileName);
                  }).height(36)
              } else if (this.getProgress(fileName) == 100) {
                Button('查看')
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    this.spo2View(fileName);
                  })
                  .height(36)
              } else {
                Button('取消下载')
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    O2Device.getInstance().getFileStop();
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

  private spo2View(fileName: string) {
    router.pushUrl({
      url: 'pages/Spo2FileViewPage',
      params: {
        path: FileUtils.getFilesDirPath(`${getContext().filesDir}/o2`, `${fileName}`),
        deviceName: this.device?.mDeviceName,
      }
    });
  }

  aboutToAppear() {
    this.device = BleDevice.copy((router.getParams() as Record<string, BleDevice>)['device']);
    //订阅事件
    emitter.on(O2Device.EVENT_SET_PARAM, () => {
      prompt.showToast({ message: `设置参数成功`, duration: 300 });
    });

    emitter.on(O2Device.EVENT_GET_INFO, (eventData: emitter.EventData) => {
      this.deviceInfo = eventData.data?.info;
      if (this.deviceInfo) {
        this.files = this.deviceInfo.fileList;
      }
    });
    emitter.on(O2Device.EVENT_GET_RT_PARAM, (eventData: emitter.EventData) => {
      this.currentSpo2 = eventData.data?.rtParam;
    });


    emitter.on(O2Device.EVENT_FILE_PROGRESS, (eventData: emitter.EventData) => {
      const item: FileTransmit = eventData.data?.fileStatus;
      const index = this.fileTransmit.findIndex((file) => file.fileName === item.fileName);
      if (index !== -1) {
        // 创建新数组并替换旧对象
        const newFileStatus = this.fileTransmit;
        newFileStatus[index] = item;
        this.fileTransmit = newFileStatus;
      } else {
        this.fileTransmit.push(item);
      }
    });

    emitter.on(O2Device.EVENT_FILE_END, (eventData: emitter.EventData) => {
      BleLog.i(JSON.stringify(eventData.data?.path));
    });


    emitter.on(O2Device.EVENT_RESET, () => {
      prompt.showToast({ message: `恢复出厂成功`, duration: 300 });
    });
  }

  aboutToDisappear() {
    // 取消事件。
    emitter.off(O2Device.EVENT_SET_PARAM);
    emitter.off(O2Device.EVENT_GET_INFO);
    emitter.off(O2Device.EVENT_GET_RT_PARAM);
    emitter.off(O2Device.EVENT_FILE_PROGRESS);
    emitter.off(O2Device.EVENT_FILE_END);
    emitter.off(O2Device.EVENT_RESET);

    O2Device.getInstance().stopRealTimeParam();
  }
}