class CapturedPost {
  const CapturedPost({
    required this.imageLocalPath,
    required this.caption,
    this.amountVnd,
  });

  final String imageLocalPath;
  final String caption;
  final int? amountVnd;
}