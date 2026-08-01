import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/report_provider.dart';

class Step3ContactScreen extends StatefulWidget {
  const Step3ContactScreen({super.key});

  @override
  State<Step3ContactScreen> createState() => _Step3ContactScreenState();
}

class _Step3ContactScreenState extends State<Step3ContactScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ReportProvider>(context, listen: false);
    _phoneController.text = provider.currentReport.contactPhone ?? '';
    _emailController.text = provider.currentReport.contactEmail ?? '';
    _whatsappController.text = provider.currentReport.contactWhatsapp ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReportProvider>(context);
    final report = provider.currentReport;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Comment peut-on te recontacter ?",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Indique au moins un moyen si tu souhaites qu'on t'aide.",
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
          const SizedBox(height: 24),

          // Anonymous Option Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: report.isAnonymous ? AppColors.primaryBlue : AppColors.borderLight,
                width: report.isAnonymous ? 2 : 1,
              ),
              backgroundColor: report.isAnonymous ? AppColors.cardBg : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              setState(() {
                _phoneController.clear();
                _emailController.clear();
                _whatsappController.clear();
              });
              provider.updateReport(
                isAnonymous: true,
                contactPhone: null,
                contactEmail: null,
                contactWhatsapp: null,
              );
            },
            icon: IconUtils.buildIcon(
              FontAwesomeIcons.userSecret,
              color: report.isAnonymous ? AppColors.primaryBlue : AppColors.textSecondary,
              size: 18,
            ),
            label: Text(
              "Rester 100% Anonyme",
              style: TextStyle(
                color: report.isAnonymous ? AppColors.primaryBlue : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OU DONNER TES COORDONNÉES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),

          // Phone Field
          _buildTextField(
            controller: _phoneController,
            label: "Téléphone",
            hint: "ex: 06 12 34 56 78",
            icon: FontAwesomeIcons.phone,
            onChanged: (val) {
              provider.updateReport(
                contactPhone: val,
                isAnonymous: false,
              );
            },
          ),
          const SizedBox(height: 14),

          // WhatsApp Field
          _buildTextField(
            controller: _whatsappController,
            label: "WhatsApp",
            hint: "ex: +212 6 12 34 56 78",
            icon: FontAwesomeIcons.whatsapp,
            iconColor: AppColors.whatsappGreen,
            onChanged: (val) {
              provider.updateReport(
                contactWhatsapp: val,
                isAnonymous: false,
              );
            },
          ),
          const SizedBox(height: 14),

          // Email Field
          _buildTextField(
            controller: _emailController,
            label: "E-mail",
            hint: "ex: monadresse@exemple.com",
            icon: FontAwesomeIcons.envelope,
            onChanged: (val) {
              provider.updateReport(
                contactEmail: val,
                isAnonymous: false,
              );
            },
          ),

          const SizedBox(height: 20),

          // Confidentiality Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                IconUtils.buildIcon(FontAwesomeIcons.shieldHalved, color: AppColors.primaryBlue, size: 16),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Vos coordonnées restent strictement confidentielles et ne seront jamais divulguées.",
                    style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required dynamic icon,
    Color? iconColor,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.cardTitle.copyWith(fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: IconUtils.buildIcon(
                icon,
                color: iconColor ?? AppColors.primaryBlue,
                size: 16,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
