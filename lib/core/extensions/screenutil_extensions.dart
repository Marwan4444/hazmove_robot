import 'package:flutter_screenutil/flutter_screenutil.dart';

extension ScreenUtilExtensions on num {
  double get staticWidth => w;
  double get staticHeight => h;
  double get staticFontSize => sp;
  double get staticRadius => r;
}
