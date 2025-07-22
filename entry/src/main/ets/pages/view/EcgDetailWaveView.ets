import { PxUtils, TimeUtils } from '../util/Utils';

@Component
export struct Er3DetailWaveView {
  // 数据传递
  @Prop public waveData: number[] = [];
  @Prop public timeTemp: number = 0;
  @Prop public samplingRate: number = 125; // 采样率
  @Prop public waveScale: number = 1.0; // 放大系数
  @Prop public speed: number = 6.25; // 走速 mm/s
  private gridSize: number = 5; // 1mm对应的像素
  private nv: number = 0.5; // 2个数据点之间的px
  @State private totalHeight: number = 400;
  private lineHeight: number = 25; // 25个小格子对应1mv和0.4s
  private waveGridColor1: Color = Color.Gray;
  private waveGridColor2: Color = Color.Red;
  private waveColor: Color = Color.Black;
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  // 定义常量表示特殊数值
  private static readonly TEXT_PADDING: number = 20; // 文本边距
  private static readonly LABEL_OFFSET: number = 10; // 标签偏移量

  // 绘制网格
  private drawGrid(ctx: CanvasRenderingContext2D) {
    const canvasWidth = ctx.width || 393;
    const canvasHeight = this.totalHeight;
    ctx.strokeStyle = this.waveGridColor1;
    ctx.lineWidth = 0.4;

    // 横向网格线
    for (let y = 0; y <= canvasHeight; y += this.gridSize) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(canvasWidth, y);
      ctx.stroke();
    }

    // 纵向网格线
    for (let x = 0; x <= canvasWidth; x += this.gridSize) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, canvasHeight);
      ctx.stroke();
    }

    ctx.strokeStyle = this.waveGridColor2;
    ctx.lineWidth = 1;
    // 横向网格线
    for (let y = 0; y <= canvasHeight; y += this.gridSize * 5) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(canvasWidth, y);
      ctx.stroke();
    }

    // 纵向网格线
    for (let x = 0; x <= canvasWidth; x += this.gridSize * 5) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, canvasHeight);
      ctx.stroke();
    }
  }

  // 绘制波形
  private drawWave(ctx: CanvasRenderingContext2D) {
    if (this.waveData.length === 0) {
      return;
    }
    const baselineY = this.totalHeight / 2;

    // 贝塞尔曲线平滑
    this.ctx.beginPath();

    let prevX = 0;
    let prevY = baselineY;
    this.waveData.forEach((value, index) => {
      const x = index * this.nv;
      const y = baselineY - value * this.waveScale * this.gridSize * 10;
      if (index === 0) {
        this.ctx.moveTo(0, baselineY);
      }else {
        // 动态平滑控制点算法
        const distance = Math.hypot(x - prevX, y - prevY);
        const tension = Math.min(0.5, 30 / distance);
        const cp1x = prevX + (x - prevX) * tension;
        const cp1y = prevY;
        const cp2x = x - (x - prevX) * tension;
        const cp2y = y;
        this.ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
      }
      prevX = x;
      prevY = y;
    });
    ctx.strokeStyle = this.waveColor;
    ctx.lineWidth = 1;
    ctx.stroke();

    // 绘制时间文本
    this.ctx.font = '24px HarmonyOS Sans'; // 设置字体大小和字体族
    const timeStr = TimeUtils.convertToDateStr(this.timeTemp);
    ctx.fillText(timeStr, Er3DetailWaveView.TEXT_PADDING, this.totalHeight - Er3DetailWaveView.LABEL_OFFSET);
    ctx.fillText(`${this.speed} mm/s`, ctx.width - 60, this.totalHeight - Er3DetailWaveView.LABEL_OFFSET);
  }

  aboutToAppear(): void {
    this.gridSize = PxUtils.getPingMuSize(); // 获取像素密度
    this.totalHeight = parseInt((this.gridSize * this.lineHeight).toFixed(0));
    this.nv = PxUtils.getXNv(PxUtils.getLineSize(this.samplingRate, this.speed)) + 0.02;
  }


  build() {
    Column() {
      Canvas(this.ctx)  //上下文不要忘记了
        .width('100%')
        .height(this.totalHeight)
        .onReady(() => {
          this.refreshWaveform();
        })
    }
  }

  private refreshWaveform() {
    // 清空画布
    this.ctx.clearRect(0, 0, this.ctx.width, this.ctx.height);
    this.drawGrid(this.ctx);
    this.drawWave(this.ctx);
  }
}
