import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:write_up/app/theme_data/app_colors.dart';

import 'package:write_up/main.dart';

class AppSnackbar {
  static void show(
    BuildContext? context, {
    required String title,
    required String message,
    String? iconAsset = 'assets/icons/alert-01-stroke-rounded.svg',
    VoidCallback? onDismiss,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    final state = scaffoldMessengerKey.currentState;
    if (state == null) return;

    state.clearSnackBars();
    state.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (iconAsset != null) ...[
              SvgPicture.asset(
                iconAsset,
                colorFilter: const ColorFilter.mode(
                  AppColors.forest1,
                  BlendMode.srcIn,
                ),
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.forest6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.forest4,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                onDismiss?.call();
              },
              child: const Text(
                'DISMISS',
                style: TextStyle(
                  color: AppColors.forest2,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.forest1,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: (scaffoldMessengerKey.currentContext != null
              ? MediaQuery.of(
                      scaffoldMessengerKey.currentContext!,
                    ).size.height -
                    MediaQuery.of(
                      scaffoldMessengerKey.currentContext!,
                    ).padding.top -
                    160
              : 600),
        ),
        duration: duration,
      ),
    );
  }

  static void showSuccess(BuildContext? context, {String? message}) {
    show(
      context,
      title: 'Success',
      message: message ?? 'Action completed successfully',
      iconAsset: 'assets/icons/checkmark-square-03-stroke-rounded.svg',
    );
  }
}
