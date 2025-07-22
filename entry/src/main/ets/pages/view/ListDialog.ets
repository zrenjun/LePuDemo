
@CustomDialog
export default struct ListDialog {
  controller: CustomDialogController
  title: string | Resource = 'title';
  items: string[] = ['item1', 'item2'];
  onclick: (which:number) => void = (which:number)=>{};

  build() {
    Column() {
      Text(this.title).fontSize(20).fontWeight(FontWeight.Bold)
      List(){
          ForEach(this.items,
              (item:string,index:number) => {
                  ListItem() {
                      Column(){
                          Text(item).fontSize(18).height(40)
                      }.width('100%').padding({top:5, bottom: 5}).alignItems(HorizontalAlign.Start)
                  }.onClick(() => {
                    this.controller.close();
                    this.onclick(index);
                  })
              },
              (item:string) => item)
      }.width('100%')
    }.margin(10)
  }
}
