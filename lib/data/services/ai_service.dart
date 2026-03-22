import 'dart:math';
import 'package:http/http.dart' as http;

class AIService {
  // Directly using the API endpoint inside the app
  static const String _baseUrl = 'https://qudata.com/ru/includes/sendmail/chat.php';
  static final _random = Random();

  static Future<String?> getAIResponse(String prompt, String category) async {
    final String userId = _generateRandomHex(32);
    
    try {
      // Direct Fetch
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: {
          'message': prompt,
          'dialogs[0][role]': 'user',
          'dialogs[0][content]': prompt,
          'userid': userId,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return _cleanResponse(response.body);
        }
      }
      return "خطأ في الاستجابة من السيرفر: ${response.statusCode}";
    } catch (e) {
      print('AI Service Error: $e');
      // If prompt has 'تحدي', the error message should be relevant
      return "نعتذر، لم أتمكن من جلب محتوى ذكي الآن! (خطأ في الاتصال)";
    }
  }

  static String _generateRandomHex(int length) {
    const hexChars = '0123456789abcdef';
    return List.generate(length, (index) => hexChars[_random.nextInt(16)]).join();
  }

  static String _cleanResponse(String response) {
    String cleaned = response.trim();
    if (cleaned.startsWith("تحدي: ")) cleaned = cleaned.replaceFirst("تحدي: ", "");
    if (cleaned.startsWith("السؤال: ")) cleaned = cleaned.replaceFirst("السؤال: ", "");
    return cleaned;
  }

  // Removed all local fallbacks as requested
  static Future<String?> getChallenge() => 
    getAIResponse('اعطني تحدي ممتع باللهجة العراقية مع كتابة التحدي فقط دون اضافة اي نص اخر', 'تحدي الأوامر');

  static Future<String?> getConfession() => 
    getAIResponse('اعطني سؤال اعتراف جريء باللهجة العراقية مع كتابة السؤال فقط دون اضافة اي نص اخر', 'إعترافات');

  static Future<String?> getWrongAnswerQuestion() => 
    getAIResponse('اعطني سؤال معلومات عامة بسيط باللهجة العراقية مع كتابة السؤال فقط دون اضافة اي نص اخر، بشرط ان يجاوب عليه المستخدم بخطأ', 'جاوب خطأ');

  static Future<String?> getNoWordTopic() => 
    getAIResponse('اعطني كلمة او اسم شخصية مشهورة او فيلم عراقي للعبة ولا كلمة باللهجة العراقية مع كتابة الكلمة فقط دون اضافة اي نص اخر', 'ولا كلمة');

  static Future<String?> getSpyTopic() => 
    getAIResponse('اعطني اسم شيء او مكان مشهور جداً في العراق للعبة الجاسوس مع كتابة الاسم فقط دون اضافة اي نص اخر', 'الجاسوس');
}
