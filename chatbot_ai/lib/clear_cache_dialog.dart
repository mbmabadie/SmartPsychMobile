import 'package:chatbot_ai/src/app_colors.dart';
import 'package:chatbot_ai/src/baab_button.dart';
import 'package:chatbot_ai/src/baab_cancel_button.dart';
import 'package:chatbot_ai/src/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'device/device_utils.dart';
import 'flutter_chat_ui.dart';
import 'src/extensions/extensions.dart';



class ClearCacheDialog extends StatefulWidget {

  const ClearCacheDialog(
      {super.key,
        required this.title,
        required this.subTitle,
        required this.onConfirm,
        required this.confirmText,
        required this.cancelText,
        this.confirmButtonColor = baabRedColor2,});
  final Function() onConfirm;
  final String title;
  final String subTitle;
  final String confirmText;
  final String cancelText;
  final Color confirmButtonColor;

  @override
  State<StatefulWidget> createState() => ClearCacheDialogState();
}

class ClearCacheDialogState extends State<ClearCacheDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    scaleAnimation =
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack);

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return
      Center(
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(8),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenUtil().setSp(10.0)),),),
              child:Padding(
                padding: EdgeInsets.symmetric(horizontal: 22.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: context.textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        widget.subTitle,
                        style: context.textTheme.bodyLarge!.copyWith(fontSize: 13,
                          color: AppColors.blackLight,),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 130.w,
                          height: 35.h,
                          child: BaabButton(
                            style: context.theme.elevatedButtonTheme.style!.copyWith(
                              backgroundColor:
                              WidgetStateProperty.all(widget.confirmButtonColor),
                              textStyle: WidgetStateProperty.all(
                                context.textTheme.labelLarge!.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            onPressed: widget.onConfirm,
                            child: Text(widget.confirmText),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        BaabCancelButton(width: 130.w, height: 35.h,cancelText: widget.cancelText,),
                      ],
                    ),
                  ],
                ),
              ),),
          ),
        ),
      );
  }
}
