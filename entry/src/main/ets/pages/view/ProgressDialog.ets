
@CustomDialog
export default struct ProgressDialog {
  controller: CustomDialogController

  build() {
    Stack() {
      LoadingProgress()
        .width(100)
        .height(100)
        .color(Color.Blue)
        .alignSelf(ItemAlign.Center)
    }
  }
}
