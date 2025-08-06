import { common } from '@kit.AbilityKit';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import { BusinessError, usbManager } from '@kit.BasicServicesKit';
import { picker } from '@kit.CoreFileKit';
import FileUtils from '@lepu/lepuhmble/src/main/ets/utils/FileUtils';
import { prompt } from '@kit.ArkUI';

@Entry
@Component
struct UsbFileCopyPage {
  @State message: string = '点击连接USB设备';
  @State uris: string[] = [];

  checkUsbDevice(): boolean {
    let deviceList: Array<usbManager.USBDevice> = usbManager.getDevices();
    if (deviceList.length === 0) {
      this.message = '未检测到USB设备';
      return false;
    }
    this.message = `已连接USB设备`;
    return true;
  }

  // 执行拷贝操作
  startCopy(uri: string) {
    const fileName = uri.substring(uri.lastIndexOf('/') + 1);
    const filePath = FileUtils.getFilesDirPath(`${getContext().filesDir}/er1`, `${fileName}`);
    FileUtils.readStream(uri)
      .then((data) => {
        FileUtils.writeStream(filePath, data, 0)
          .then(() => {
            prompt.showToast({ message: `文件已保存至${filePath}`, duration: 300 });
          })
          .catch((err: BusinessError) => {
            BleLog.e(`writeStream failed, code is ${err.code}, message is ${err.message}`);
          });
      })
      .catch((err: BusinessError) => {
        BleLog.e(`readStream failed, code is ${err.code}, message is ${err.message}`);
      });
  }

  fileSelect() {
    const documentSelectOptions = new picker.DocumentSelectOptions();
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const documentViewPicker = new picker.DocumentViewPicker(context);
    documentViewPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
      this.uris = documentSelectResult;
      //file://docs/storage/External/8800-0000/R20250513102135
      BleLog.e('documentViewPicker.select: ' + this.uris);
    }).catch((err: BusinessError) => {
      BleLog.e(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
    })
  }

  build() {
    Column() {
      Text(this.message)
        .fontSize(18)
        .margin(10)

      Button('选择文件')
        .onClick(() => {
          if (this.checkUsbDevice()) {
            this.fileSelect()
          }
        })
        .margin(10)

      List() {
        ForEach(this.uris, (uri: string) => {
          ListItem() {
            Row() {
              Text(uri.substring(uri.lastIndexOf('/') + 1))
                .fontSize($r('app.float.page_text_font_size'))
                .fontWeight(FontWeight.Bold)
                .margin({ left: 16 })
                .width('45%')

              Button('拷贝')
                .fontSize($r('app.float.page_text_font_size'))
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                  this.startCopy(uri);
                }).height(36)
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
    .padding(20)
  }
}