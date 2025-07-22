import { prompt, router } from '@kit.ArkUI';
import FileUtils from '@lepu/lepuhmble/src/main/ets/utils/FileUtils';
import Er1EcgFile from '@lepu/lepuhmble/src/main/ets/device/er1/Er1EcgFile';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import EcgFilter from '@lepu/lepuhmble/src/main/ets/utils/EcgFilter';
import { PxUtils, TimeUtils } from './util/Utils';
import { Er3DetailWaveView } from './view/EcgDetailWaveView';
import ProgressDialog from './view/ProgressDialog';


@Entry
@Component
struct EcgFileViewPage {
  @State private ecgDataList: EcgData[] = [];
  private sampling: number = 125;
  private speed: number = 6.25;
  private waveScale: number = 1.0;
  private time: number = 0;
  private dataLine: number = 0;
  private totalPages: number = 0;
  private currentPage: number = 0;
  private rawData: Int16Array = new Int16Array(0);
  // 分页配置
  private readonly PAGE_SIZE = 10; // 每次加载10页数据

  build() {
    Column() {
      Text('心电详情')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)

      List() {
        ForEach(this.ecgDataList, (ecgData: EcgData) => {
          ListItem() {
            Er3DetailWaveView({
              timeTemp: ecgData.time,
              waveData: ecgData.data,
              samplingRate: this.sampling,
              waveScale: this.waveScale,
              speed: this.speed
            })
          }
        }, (ecgData: EcgData) => `${ecgData.time}`)
      }
      .onReachEnd(() => this.loadMoreData()) // 列表滚动到底部事件
      .edgeEffect(EdgeEffect.None) // 禁用默认滑动效果
    }
    .height('100%')
    .width('100%')
  }

  // 加载更多数据
  async loadMoreData() {
    if (this.currentPage >= this.totalPages) {
      return;
    }
    const startPage = this.currentPage;
    const endPage = Math.min(startPage + this.PAGE_SIZE, this.totalPages);
    // 分片处理数据
    const startIndex = startPage * this.dataLine;
    const endIndex = Math.min(endPage * this.dataLine, this.rawData.length);
    const newData: EcgData[] = [];
    for (let i = startIndex; i < endIndex; i += this.dataLine) {
      newData.push(new EcgData(this.calculateTime(i), this.rawData.subarray(i, i + this.dataLine)));
    }
    this.ecgDataList = this.ecgDataList.concat(newData);
    this.currentPage = endPage;
  }

  // 计算时间戳
  private calculateTime(index: number): number {
    const millisecond = Math.round((index / this.sampling) * 1000);
    return this.time + millisecond;
  }

  private progressDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: ProgressDialog()
  });

  aboutToAppear() {
    this.progressDialogCtrl.open();
    const params = router.getParams() as Record<string, string>;
    const path = params['path'];
    this.sampling = parseInt(params['sampling'] || '0'); // 默认值
    const name = params['name']; // 文件名称 20250701105049
    this.time = TimeUtils.convertToTimestamp(name);
    BleLog.e(`time : ${this.time}`)
    this.dataLine = PxUtils.getLineSize(this.sampling, this.speed);
    BleLog.e(`dataLine : ${this.dataLine}`)
    if (!path || !FileUtils.accessSync(path)) {
      prompt.showToast({ message: "文件不存在", duration: 300 });
      this.progressDialogCtrl.close();
      return;
    }
    EcgFilter.resetFilter();
    FileUtils.readStream(path).then((data) => {
      this.rawData = new Er1EcgFile(data).shortData;  // todo 区分设备
      this.totalPages =
        Math.ceil(this.rawData.length / (PxUtils.getLineSize(this.sampling, this.speed) * this.PAGE_SIZE));
      this.loadMoreData(); // 初始加载第一页
      this.progressDialogCtrl.close();
      BleLog.e(`totalPages : ${this.totalPages}`);
    });
  }
}


export class EcgData {
  time: number = 0; //时间戳
  data: number[] = []; //数据

  constructor(time: number, data: Int16Array) {
    this.time = time;
    const filter = EcgFilter.shortFilter(Array.from(data));
    filter.forEach((value) => {
      this.data.push(value * 0.002467); // todo 区分设备
    })
  }
}
