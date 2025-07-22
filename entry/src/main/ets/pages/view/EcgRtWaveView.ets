import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import { PxUtils } from '../util/Utils';
import { emitter } from '@kit.BasicServicesKit';
import EcgFilter from '@lepu/lepuhmble/src/main/ets/utils/EcgFilter';

@Component
export struct ECGWaveform {
  public static EVENT_WAVE_DATA: string = "waveData";
  private static MAX_BUFFER_SIZE: number = 1000;
  private gridSize: number = 5; // 一毫米网格大小
  private nv: number = 0.5; // 2个数据点之间的px
  private dataQueue: number[] = [];
  private dataSrc: number[] = [];
  private isAnimating: boolean = false;
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  @Prop public samplingRate: number = 125; // 采样率
  @Prop public waveScale: number = 1.0; // 放大系数
  @Prop public speed: number = 6.25; // 走速 mm/s
  @State waveColor: Color = Color.Black;
  @State waveGridColor1: Color = Color.Gray;
  @State waveGridColor2: Color = Color.Red;
  private orderSweep: number = 0 //当前绘制波形数据索引

  receiveData(incomingData: number[]) {
    // 校验输入有效性
    if (!Array.isArray(incomingData) || incomingData.some(isNaN)) {
      console.warn("Invalid data received, skipping.");
      return;
    }
    this.dataQueue = this.dataQueue.concat(incomingData);
  }

  private refreshWaveform() {
    if (!this.isAnimating) {
      return;
    }
    //一秒60帧
    for (let i = 0; i < this.samplingRate / 60; i++) {
      const data = this.dataQueue.shift();
      if (data) {
        if (this.dataSrc.length == ECGWaveform.MAX_BUFFER_SIZE) {
          this.dataSrc[this.orderSweep] = data;
          if (++this.orderSweep >= ECGWaveform.MAX_BUFFER_SIZE) {
            this.orderSweep = 0;
          }
        } else {
          this.dataSrc.push(data)
          this.orderSweep = 0
        }
      }
    }
    // 清空画布
    this.ctx.clearRect(0, 0, this.ctx.width, this.ctx.height);
    // 重新绘制
    this.drawGrid(this.ctx);
    this.drawWaveform(this.ctx);
    //动态调节避免视觉卡顿
    let interval = 0;
    const length = this.dataSrc.length;
    if (length > this.samplingRate) {
      interval = 18
    } else if (length > this.samplingRate / 2) {
      interval = 24;
    } else {
      interval = 30;
    }
    // 下一帧
    setTimeout(() => {
      this.refreshWaveform();
    }, interval);
  }

  private drawGrid(ctx: CanvasRenderingContext2D) {
    const gridSize = this.gridSize;
    const canvasWidth = ctx.width || 200; // 提供默认值
    const canvasHeight = ctx.height || 200;

    ctx.strokeStyle = this.waveGridColor1;
    ctx.lineWidth = 0.4;

    // 横向网格线
    for (let y = 0; y <= canvasHeight; y += gridSize) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(canvasWidth, y);
      ctx.stroke();
    }

    // 纵向网格线
    for (let x = 0; x <= canvasWidth; x += gridSize) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, canvasHeight);
      ctx.stroke();
    }

    ctx.strokeStyle = this.waveGridColor2;
    ctx.lineWidth = 1;
    // 横向网格线
    for (let y = 0; y <= canvasHeight; y += gridSize * 5) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(canvasWidth, y);
      ctx.stroke();
    }

    // 纵向网格线
    for (let x = 0; x <= canvasWidth; x += gridSize * 5) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, canvasHeight);
      ctx.stroke();
    }
  }

  private drawWaveform(ctx: CanvasRenderingContext2D) {
    const centerY = ctx.height / 2;
    const scale = this.waveScale * this.gridSize * 10;
    const path = new Path2D();
    ctx.beginPath();
    path.moveTo(0, centerY);
    let i = 0;
    while (i < this.dataSrc.length) {
      if (i == this.orderSweep && i < ECGWaveform.MAX_BUFFER_SIZE - 5) {
        const x = (i + 4) * this.nv;
        const y = centerY - this.dataSrc[i + 4] * scale;
        ctx.moveTo(x, y);
        i = i + 4
      } else {
        const x1 = i * this.nv;
        const y1 = centerY - this.dataSrc[i] * scale;
        ctx.lineTo(x1, y1);
      }
      i++;
    }
    ctx.strokeStyle = this.waveColor;
    ctx.lineWidth = 1;
    ctx.stroke();
  }

  build() {
    Column() {
      Canvas(this.ctx)
        .width('100%')
        .height(200)
        .onReady(() => {
        })
    }
    .onAppear(() => {
      this.gridSize = PxUtils.getPingMuSize(); //5.62
      ECGWaveform.MAX_BUFFER_SIZE = PxUtils.getLineSize(this.samplingRate, this.speed); //1400
      this.nv = PxUtils.getXNv(ECGWaveform.MAX_BUFFER_SIZE) + 0.02;
      BleLog.e('nv:' + this.nv);
      this.isAnimating = true;
      this.refreshWaveform();
      EcgFilter.resetFilter();
      emitter.on(ECGWaveform.EVENT_WAVE_DATA, (eventData: emitter.EventData) => {
        this.receiveData(eventData.data?.wave);
      });
    })
    .onDisAppear(() => {
      this.isAnimating = false;
      emitter.off(ECGWaveform.EVENT_WAVE_DATA);
    });
  }
}
