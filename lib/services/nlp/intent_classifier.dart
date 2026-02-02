// Intent Classifier for NLP
// Recognizes user intents from text using keyword scoring and pattern matching

import 'fuzzy_matcher.dart';
import 'preprocessor.dart';

enum IntentType {
  alarm,
  reminder,
  note,
  listAlarms,
  listNotes,
  listReminders,
  deleteAlarm,
  deleteNote,
  deleteReminder,
  greeting,
  farewell,
  thanks,
  help,
  about,
  time,
  date,
  weather,
  compliment,
  insult,
  joke,
  smallTalk,
  math,
  horoscope,
  budget,
  emotional,
  affirmative,
  negative,
  setName,
  unclear,
}

class Intent {
  final IntentType type;
  final double confidence;
  final String? subType;
  final Map<String, dynamic> metadata;

  Intent({
    required this.type,
    required this.confidence,
    this.subType,
    this.metadata = const {},
  });

  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.4;

  @override
  String toString() => 'Intent($type, ${confidence.toStringAsFixed(2)})';
}

class IntentClassifier {
  // Intent keywords with weights
  static const Map<IntentType, Map<String, double>> _intentKeywords = {
    IntentType.alarm: {
      // Turkish - High weight
      'alarm': 1.0, 'çalar saat': 1.0, 'calar saat': 1.0,
      'uyandır': 0.9, 'uyandir': 0.9, 'kaldır': 0.8, 'kaldir': 0.8,
      'alarm kur': 1.0, 'alarm ayarla': 1.0, 'uyandırma': 0.9, 'uyandirma': 0.9,
      'saat kur': 0.8, 'saati kur': 0.8, 'zil kur': 0.9,
      'beni uyandır': 1.0, 'sabah kaldır': 0.9, 'sabah uyandır': 0.9,
      'çalsın': 0.7, 'calsin': 0.7, 'çal': 0.6, 'cal': 0.6,
      // Turkish - Time-specific patterns
      'sabahleyin': 0.6, 'sabah erkenden': 0.7, 'akşam': 0.5,
      // Turkish - Medium weight
      'uyku': 0.5, 'uyanma': 0.6, 'kalk': 0.5, 'reveille': 0.7,
      'zil': 0.5, 'erken kalk': 0.6, 'saat kaçta kalk': 0.6,
      // English - High weight
      'set alarm': 1.0, 'alarm clock': 1.0, 'wake me': 0.9,
      'wake up': 0.8, 'set timer': 0.7, 'wake me up': 1.0,
      'ring': 0.6, 'wake': 0.7, 'alarm for': 0.9,
      // English - Medium weight
      'alert me': 0.6, 'buzz': 0.5, "o'clock": 0.4, 'get up': 0.5,
      'morning alarm': 0.8, 'set wake': 0.8,
    },
    IntentType.reminder: {
      // Turkish - High weight
      'hatırlat': 1.0, 'hatirla': 0.9, 'anımsat': 0.9, 'animsat': 0.9,
      'hatırlatıcı': 1.0, 'hatirlatici': 1.0, 'hatırlatıcı oluştur': 1.0,
      'unutma': 0.8, 'unutturma': 0.9, 'aklına gel': 0.7, 'aklina gel': 0.7,
      'haber ver': 0.8,
      'bildir': 0.7,
      'uyar': 0.7,
      'aklımda tut': 0.8,
      'aklimda tut': 0.8,
      // Turkish - Context-specific
      'randevu': 0.7,
      'toplantı': 0.6,
      'toplanti': 0.6,
      'buluşma': 0.6,
      'bulusma': 0.6,
      // Turkish - Medium weight
      'etkinlik': 0.6,
      'plan': 0.4,
      'program': 0.4,
      'ajanda': 0.5,
      'işim var': 0.5,
      'yapılacak': 0.5, 'yapilacak': 0.5,
      // English - High weight
      'remind': 1.0, 'reminder': 1.0, "don't forget": 0.9, 'dont forget': 0.9,
      'notify': 0.8, 'notification': 0.7, 'alert': 0.7, 'remember': 0.8,
      'ping me': 0.7, 'remind me': 1.0, 'create reminder': 1.0,
      // English - Context-specific
      'meeting': 0.6, 'appointment': 0.7, 'event': 0.5, 'schedule': 0.5,
      // English - Medium weight
      'calendar': 0.5, 'have to': 0.4, 'need to': 0.5, 'must': 0.4,
      'todo': 0.5, 'task': 0.4,
    },
    IntentType.note: {
      // Turkish - High weight
      'not': 0.8, 'not al': 1.0, 'not yaz': 1.0, 'kaydet': 0.9,
      'yaz': 0.6, 'ekle': 0.5, 'not ekle': 1.0, 'bunu yaz': 0.9,
      'not et': 1.0, 'kenara yaz': 0.8, 'şunu kaydet': 0.9, 'sunu kaydet': 0.9,
      // Turkish - List-specific
      'liste': 0.7, 'listesi': 0.8, 'liste yap': 0.9, 'liste oluştur': 0.9,
      'alışveriş': 0.8,
      'alisveris': 0.8,
      'alışveriş listesi': 1.0,
      'alisveris listesi': 1.0,
      'market': 0.7,
      'market listesi': 0.9,
      'süpermarket': 0.7,
      'supermarket': 0.7,
      'yapılacaklar': 0.8, 'yapilacaklar': 0.8, 'yapılacaklar listesi': 1.0,
      // Turkish - Medium weight
      'defteri': 0.7, 'memo': 0.8, 'görev': 0.5, 'gorev': 0.5,
      'iş': 0.4, 'is': 0.3, 'ihtiyaç': 0.5, 'ihtiyac': 0.5,
      // English - High weight
      'note': 0.8, 'take note': 1.0, 'write': 0.7, 'save': 0.7,
      'add note': 1.0, 'jot down': 0.9, 'record': 0.6,
      'write down': 0.9, 'keep note': 0.8, 'write this': 0.9, 'save this': 0.9,
      // English - List-specific
      'list': 0.7, 'shopping': 0.8, 'shopping list': 1.0, 'grocery': 0.7,
      'grocery list': 0.9, 'make list': 0.9, 'create list': 0.9,
      'todo': 0.8, 'to-do': 0.8, 'todo list': 1.0, 'to-do list': 1.0,
      'task list': 0.8, 'checklist': 0.8,
      // English - Medium weight
      'task': 0.5, 'item': 0.4, 'things to buy': 0.8,
    },
    IntentType.listAlarms: {
      // Turkish
      'alarmlarım': 1.0, 'alarmlarim': 1.0, 'alarmları göster': 1.0,
      'alarmlari goster': 1.0, 'alarmları listele': 1.0,
      'kurulu alarmlar': 0.9, 'aktif alarmlar': 0.9,
      'ne zaman kalkacağım': 0.7, 'alarmlarıma bak': 0.8,
      // English
      'my alarms': 1.0, 'show alarms': 1.0, 'list alarms': 1.0,
      'what alarms': 0.8, 'alarm list': 0.9,
    },
    IntentType.listNotes: {
      // Turkish
      'notlarım': 1.0, 'notlarim': 1.0, 'notları göster': 1.0,
      'notlari goster': 1.0, 'notları listele': 1.0,
      'kayıtlı notlar': 0.9, 'notlarıma bak': 0.8,
      // English
      'my notes': 1.0, 'show notes': 1.0, 'list notes': 1.0,
      'what notes': 0.8, 'note list': 0.9,
    },
    IntentType.listReminders: {
      // Turkish
      'hatırlatıcılarım': 1.0, 'hatirlaticilarim': 1.0,
      'hatırlatıcıları göster': 1.0, 'hatiratlaricilari goster': 1.0,
      'bekleyen hatırlatıcılar': 0.9, 'hatırlatıcılarıma bak': 0.8,
      'görevlerim': 0.8, 'gorevlerim': 0.8,
      // English
      'my reminders': 1.0, 'show reminders': 1.0, 'list reminders': 1.0,
      'what reminders': 0.8, 'reminder list': 0.9, 'my tasks': 0.8,
    },
    IntentType.deleteAlarm: {
      // Turkish
      'alarmı sil': 1.0, 'alarmi sil': 1.0, 'alarmı kaldır': 1.0,
      'alarmi kaldir': 1.0, 'alarmı iptal et': 0.9, 'alarm sil': 0.9,
      'alarmı temizle': 0.8, 'alarmi temizle': 0.8, 'alarmı çıkar': 0.8,
      'alarmi cikar': 0.8, 'alarmı kapat': 0.7,
      // English
      'delete alarm': 1.0, 'remove alarm': 1.0, 'cancel alarm': 0.9,
      'clear alarm': 0.8, 'turn off alarm': 0.7, 'get rid of alarm': 0.8,
      'stop alarm': 0.6,
    },
    IntentType.deleteNote: {
      // Turkish
      'notu sil': 1.0, 'not sil': 0.9, 'notu kaldır': 0.9,
      'notu temizle': 0.8, 'notu çıkar': 0.8, 'notu cikar': 0.8,
      'listeyi sil': 0.9, 'listeyi kaldır': 0.9,
      // English
      'delete note': 1.0, 'remove note': 1.0, 'clear note': 0.8,
      'get rid of note': 0.8, 'delete list': 0.9, 'remove list': 0.9,
    },
    IntentType.deleteReminder: {
      // Turkish
      'hatırlatıcıyı sil': 1.0,
      'hatirlaticiyi sil': 1.0,
      'hatırlatıcı sil': 0.9,
      'hatırlatıcıyı iptal': 0.9, 'hatırlatıcıyı kaldır': 0.9,
      'hatirlaticiyi kaldir': 0.9, 'hatırlatıcıyı temizle': 0.8,
      'görevi sil': 0.8, 'gorevi sil': 0.8, 'randevuyu iptal': 0.7,
      // English
      'delete reminder': 1.0, 'remove reminder': 1.0, 'cancel reminder': 0.9,
      'clear reminder': 0.8, 'get rid of reminder': 0.8,
      'delete task': 0.8, 'cancel appointment': 0.7, 'cancel meeting': 0.7,
    },
    IntentType.greeting: {
      // Turkish
      'merhaba': 1.0, 'selam': 1.0, 'selamlar': 1.0,
      'günaydın': 1.0, 'gunaydin': 1.0, 'iyi günler': 1.0, 'iyi gunler': 1.0,
      'iyi akşamlar': 1.0, 'iyi aksamlar': 1.0, 'iyi geceler': 0.9,
      'naber': 0.8, 'napıyorsun': 0.7, 'napiyorsun': 0.7,
      'nasılsın': 0.8, 'nasilsin': 0.8, 'ne haber': 0.8,
      'hey': 0.7, 'heyy': 0.7, 'heyyy': 0.7, 'alo': 0.5,
      'sa': 0.6, 'slm': 0.6, 'mrb': 0.6, 'sea': 0.5,
      // English
      'hello': 1.0, 'hi': 0.9, 'greetings': 1.0,
      'good morning': 1.0, 'good afternoon': 1.0, 'good evening': 1.0,
      'how are you': 0.8, "what's up": 0.7, 'whats up': 0.7,
      'howdy': 0.7, 'sup': 0.6, 'yo': 0.5, 'hey there': 0.8,
      'hiya': 0.7,
    },
    IntentType.farewell: {
      // Turkish
      'görüşürüz': 1.0, 'gorusuruz': 1.0, 'hoşça kal': 1.0, 'hosca kal': 1.0,
      'güle güle': 1.0, 'gule gule': 1.0, 'kendine iyi bak': 0.8,
      'iyi geceler': 0.8, 'yarın görüşürüz': 0.9, 'yarin gorusuruz': 0.9,
      'bay bay': 0.9, 'baybay': 0.9, 'bb': 0.6, 'kaçtım ben': 0.7,
      'ben kaçar': 0.7,
      // English
      'goodbye': 1.0, 'bye': 0.9, 'bye bye': 1.0, 'see you': 0.9,
      'take care': 0.8, 'later': 0.6, 'gotta go': 0.7,
      'see ya': 0.8, 'cya': 0.6, 'farewell': 1.0, 'gn': 0.5,
    },
    IntentType.thanks: {
      // Turkish
      'teşekkürler': 1.0, 'tesekkurler': 1.0, 'teşekkür': 0.9, 'tesekkur': 0.9,
      'sağol': 0.9, 'sagol': 0.9, 'sağ ol': 0.9, 'sag ol': 0.9,
      'eyvallah': 0.8, 'eyv': 0.6, 'saol': 0.8,
      'çok teşekkürler': 1.0, 'cok tesekkurler': 1.0,
      'minnettarım': 0.9, 'minnettarim': 0.9, 'adamsın': 0.6,
      'kralsın': 0.6,
      // English
      'thank you': 1.0, 'thanks': 1.0, 'thx': 0.7, 'ty': 0.6,
      'thank u': 0.9, 'much appreciated': 0.9, 'appreciate it': 0.8,
      'grateful': 0.7, 'thanks a lot': 1.0, 'many thanks': 1.0,
    },
    IntentType.help: {
      // Turkish
      'yardım': 1.0, 'yardim': 1.0, 'yardım et': 1.0, 'yardim et': 1.0,
      'ne yapabilirsin': 1.0, 'neler yapabilirsin': 1.0,
      'özellikler': 0.9, 'ozellikler': 0.9, 'komutlar': 0.9,
      'nasıl kullanılır': 0.8, 'nasil kullanilir': 0.8,
      'açıkla': 0.7, 'acikla': 0.7, 'anlat': 0.6, 'imdat': 0.5,
      // English
      'help': 1.0, 'help me': 1.0, 'what can you do': 1.0,
      'features': 0.9, 'commands': 0.9, 'how to use': 0.8,
      'instructions': 0.7, 'guide': 0.6, 'tutorial': 0.6,
      'assist': 0.8,
    },
    IntentType.about: {
      // Turkish
      'adın ne': 1.0, 'adin ne': 1.0, 'sen kimsin': 1.0,
      'ismin ne': 0.9, 'hakkında': 0.8, 'hakkinda': 0.8,
      'seni kim yaptı': 0.9, 'seni kim yapti': 0.9,
      'yapımcı': 0.7, 'yapimci': 0.7, 'geliştirici': 0.7, 'gelistirici': 0.7,
      'versiyon': 0.6, 'sürüm': 0.6, 'surum': 0.6, 'nerelisin': 0.5,
      // English
      'what is your name': 1.0, 'who are you': 1.0, "what's your name": 1.0,
      'about': 0.7, 'about you': 0.9, 'who made you': 0.9,
      'developer': 0.6, 'creator': 0.6, 'version': 0.6,
      'where are you from': 0.5,
    },
    IntentType.time: {
      // Turkish
      'saat kaç': 1.0, 'saat kac': 1.0, 'kaç saat': 0.7, 'kac saat': 0.7,
      'şu an saat': 1.0,
      'su an saat': 1.0,
      'saati söyle': 0.9,
      'saati soyle': 0.9,
      'vakit': 0.6, 'zaman': 0.5,
      // English
      'what time': 1.0, 'current time': 1.0, 'time is it': 0.9,
      'tell me the time': 0.9, "what's the time": 1.0,
      'clock': 0.5,
    },
    IntentType.date: {
      // Turkish
      'bugün hangi gün': 1.0, 'bugun hangi gun': 1.0,
      'tarih ne': 1.0, 'bugünün tarihi': 1.0, 'bugunun tarihi': 1.0,
      'ayın kaçı': 0.9, 'ayin kaci': 0.9, 'hangi ay': 0.7,
      'hangi gün': 0.8, 'hangi gun': 0.8, 'hangi yıl': 0.7,
      // English
      'what day': 0.9, 'what is the date': 1.0, "today's date": 1.0,
      'current date': 1.0, 'which day': 0.8, 'what month': 0.7,
      'what year': 0.7,
    },
    IntentType.compliment: {
      // Turkish
      'harikasın': 1.0, 'harikasin': 1.0, 'süpersin': 1.0, 'supersin': 1.0,
      'mükemmelsin': 1.0,
      'mukemmelsin': 1.0,
      'çok iyisin': 0.9,
      'cok iyisin': 0.9,
      'teşekkürler harika': 0.9, 'bravo': 0.8, 'aferin': 0.8,
      'başarılı': 0.7, 'basarili': 0.7, 'güzelmiş': 0.7, 'guzelmis': 0.7,
      'seviyorum': 0.6, 'sevdim': 0.6,
      // English
      "you're great": 1.0, 'youre great': 1.0, 'awesome': 0.9,
      'amazing': 0.9, 'excellent': 0.9, 'wonderful': 0.9,
      'good job': 0.8, 'well done': 0.8, 'nice': 0.6,
      'love you': 0.6, 'cool': 0.6,
    },
    IntentType.joke: {
      // Turkish
      'fıkra': 0.9, 'fikra': 0.9, 'espri': 0.9, 'şaka': 0.8, 'saka': 0.8,
      'güldür beni': 1.0, 'guldur beni': 1.0, 'komik bir şey': 0.8,
      'eğlendır': 0.7, 'eglendir': 0.7, 'komiklik': 0.6,
      // English
      'joke': 1.0, 'tell me a joke': 1.0, 'funny': 0.7,
      'make me laugh': 0.9, 'something funny': 0.8, 'humor': 0.6,
    },
    IntentType.smallTalk: {
      // Turkish
      'hava nasıl': 0.7, 'hava nasil': 0.7, 'ne düşünüyorsun': 0.6,
      'ne dusunuyorsun': 0.6, 'sence': 0.5, 'ne dersin': 0.6,
      'canın sıkılıyor mu': 0.7, 'canin sikiliyor mu': 0.7,
      'sen ne yapıyorsun': 0.6, 'sen ne yapiyorsun': 0.6,
      'konuşalım': 0.7, 'sohbet edelim': 0.7,
      // English
      "how's the weather": 0.7, 'what do you think': 0.6,
      'are you bored': 0.7, 'what are you doing': 0.6,
      'tell me something': 0.5, 'chat with me': 0.7,
      "let's talk": 0.7,
    },
    IntentType.math: {
      // Turkish
      'kaç eder': 1.0, 'kac eder': 1.0, 'hesapla': 1.0,
      'toplam': 0.8, 'çarpı': 0.8, 'carpi': 0.8, 'bölü': 0.8, 'bolu': 0.8,
      'artı': 0.8, 'arti': 0.8, 'eksi': 0.8, 'çıkar': 0.8, 'cikar': 0.8,
      '+': 0.9, '-': 0.7, '*': 0.8, 'x': 0.7, '/': 0.8, '=': 0.8,
      // English
      'calculate': 1.0, 'what is': 0.7, 'plus': 0.8, 'minus': 0.8,
      'times': 0.8, 'divided': 0.8, 'equals': 0.7, 'math': 0.9,
    },
    IntentType.horoscope: {
      // Turkish
      'burç': 1.0, 'burc': 1.0, 'burçum': 1.0, 'burcum': 1.0,
      'falım': 0.9, 'falim': 0.9, 'yıldız': 0.6, 'yildiz': 0.6,
      'koç': 0.7, 'koc': 0.7, 'boğa': 0.7, 'boga': 0.7, 'ikizler': 0.7,
      'yengeç': 0.7, 'yengec': 0.7, 'aslan': 0.6, 'başak': 0.7, 'basak': 0.7,
      'terazi': 0.7, 'akrep': 0.7, 'yay': 0.6, 'oğlak': 0.7, 'oglak': 0.7,
      'kova': 0.7, 'balık': 0.7, 'balik': 0.7,
      // English
      'horoscope': 1.0, 'zodiac': 1.0, 'astrology': 0.9, 'sign': 0.6,
      'aries': 0.7, 'taurus': 0.7, 'gemini': 0.7, 'cancer': 0.6,
      'leo': 0.6, 'virgo': 0.7, 'libra': 0.7, 'scorpio': 0.7,
      'sagittarius': 0.7, 'capricorn': 0.7, 'aquarius': 0.7, 'pisces': 0.7,
    },
    IntentType.budget: {
      // Turkish
      'bütçe': 1.0, 'butce': 1.0, 'para': 0.6, 'harcama': 0.8,
      'tasarruf': 0.9, 'fatura': 0.8, 'ödeme': 0.7, 'odeme': 0.7,
      'gelir': 0.7, 'gider': 0.7, 'ekonomi': 0.6,
      // English
      'budget': 1.0, 'money': 0.6, 'expense': 0.8, 'spending': 0.8,
      'saving': 0.9, 'savings': 0.9, 'bill': 0.7, 'payment': 0.7,
      'income': 0.7, 'finance': 0.8, 'financial': 0.8,
    },
    IntentType.emotional: {
      // Turkish
      'üzgün': 1.0, 'uzgun': 1.0, 'mutlu': 1.0, 'mutsuz': 1.0,
      'stresli': 1.0, 'yorgun': 1.0, 'yalnız': 1.0, 'yalniz': 1.0,
      'motive': 0.9, 'enerjik': 0.8, 'kötü': 0.7, 'kotu': 0.7,
      'iyi': 0.5, 'harika': 0.6, 'berbat': 0.9, 'depresif': 0.9,
      // English
      'sad': 1.0, 'happy': 0.9, 'stressed': 1.0, 'tired': 1.0,
      'lonely': 1.0, 'motivated': 0.9, 'depressed': 0.9,
      'feeling': 0.6, 'mood': 0.7, 'emotion': 0.7,
    },
    IntentType.affirmative: {
      // Turkish
      'evet': 1.0, 'tamam': 0.9, 'olur': 0.9, 'peki': 0.8,
      'tabii': 0.9, 'tabi': 0.9, 'doğru': 0.8, 'dogru': 0.8,
      'kesinlikle': 0.9, 'aynen': 0.8, 'onaylıyorum': 0.9, 'onayliyorum': 0.9,
      'kabul': 0.8, 'anladım': 0.7, 'anladim': 0.7, 'ok': 0.7, 'okey': 0.7,
      'onayla': 1.0, 'yap': 0.9,
      // English
      'yes': 1.0, 'yeah': 0.9, 'yep': 0.9, 'yup': 0.8,
      'sure': 0.9, 'okay': 0.8, 'alright': 0.8,
      'correct': 0.8, 'right': 0.7, 'absolutely': 0.9, 'definitely': 0.9,
      'of course': 0.9, 'indeed': 0.8, 'confirmed': 0.8,
      'confirm': 1.0, 'do it': 0.9,
    },
    IntentType.negative: {
      // Turkish
      'hayır': 1.0, 'hayir': 1.0, 'yok': 0.8, 'olmaz': 0.9,
      'istemiyorum': 1.0, 'vazgeç': 0.9, 'vazgec': 0.9,
      'iptal': 0.9, 'yanlış': 0.7, 'yanlis': 0.7, 'değil': 0.6, 'degil': 0.6,
      'bırak': 0.8, 'birak': 0.8, 'durdur': 0.7, 'kalsın': 0.8,
      // English
      'no': 1.0, 'nope': 0.9, 'nah': 0.8, 'never': 0.9,
      "don't": 0.8, 'dont': 0.8, 'cancel': 0.9, 'stop': 0.8,
      'wrong': 0.7, 'incorrect': 0.7, "i don't want": 0.9,
      'forget it': 0.8, 'nevermind': 0.8, 'no thanks': 0.9,
    },
    IntentType.setName: {
      // Turkish - explicit name setting
      'bana ... de': 1.0, 'bana ... diye hitap et': 1.0,
      'adım': 0.9, 'adim': 0.9, 'ismim': 0.9, 'benim adım': 1.0,
      'benim adim': 1.0, 'adımı değiştir': 0.8, 'adimi degistir': 0.8,
      'bana şöyle seslen': 0.9, 'ismimi güncelle': 0.9,
      'adım şu': 0.7, 'diye hitap et': 1.0, 'diyeceksin': 0.9,
      'hitap et': 0.8, 'seslen': 0.8, 'bana de': 0.9,
      // English
      'call me': 1.0, 'my name is': 1.0, 'i am': 0.8,
      "i'm": 0.8, 'change my name': 0.9, 'update my name': 0.9,
      'set my name': 0.9, 'address me': 0.9,
    },
  };

  /// Classify intent from text
  static Intent classify(String text) {
    final normalized = Preprocessor.normalize(text);

    // Check for Math Regex first (e.g. "2+2", "5*10", "10/2")
    // Matches digits, operator, digits. Allows spaces.
    final mathRegex = RegExp(r'\d+\s*[\+\-\*\/x]\s*\d+');
    if (mathRegex.hasMatch(text)) {
      return Intent(
        type: IntentType.math,
        confidence: 1.0,
        metadata: {'matchType': 'regex'},
      );
    }

    final scores = <IntentType, double>{};

    // Calculate scores for each intent
    for (final entry in _intentKeywords.entries) {
      double score = 0;
      var matches = 0;

      for (final keyword in entry.value.entries) {
        // Exact match of the WHOLE text (high confidence for single words like "Oğlak")
        if (normalized == keyword.key) {
          score +=
              keyword.value * 2.0; // Double weight for exact full string match
          matches++;
        }
        // Substring match
        else if (normalized.contains(keyword.key)) {
          score += keyword.value;
          matches++;
        } else {
          // Fuzzy match
          if (FuzzyMatcher.containsFuzzy(
            normalized,
            keyword.key,
            threshold: 0.85,
          )) {
            score += keyword.value * 0.7; // Reduce score for fuzzy matches
            matches++;
          }
        }
      }

      if (matches > 0) {
        // Boost score if matches are found, don't punish for single matches
        // Old formula: score / (matches + 1) punished single matches
        scores[entry.key] = score;
      }
    }

    if (scores.isEmpty) {
      return Intent(type: IntentType.unclear, confidence: 0.0);
    }

    // Find best match
    var bestIntent = IntentType.unclear;
    var bestScore = 0.0;

    scores.forEach((type, score) {
      if (score > bestScore) {
        bestScore = score;
        bestIntent = type;
      }
    });

    // Normalize confidence to 0-1 range (cap at 1.0)
    final confidence = bestScore.clamp(0.0, 1.0);

    return Intent(
      type: bestIntent,
      confidence: confidence,
      metadata: {'allScores': scores},
    );
  }

  /// Get secondary intents (for compound commands)
  static List<Intent> classifyMultiple(String text, {int maxResults = 3}) {
    final normalized = Preprocessor.normalize(text);
    final scores = <IntentType, double>{};

    for (final entry in _intentKeywords.entries) {
      double score = 0;
      var matches = 0;

      for (final keyword in entry.value.entries) {
        if (normalized.contains(keyword.key)) {
          score += keyword.value;
          matches++;
        }
      }

      if (matches > 0) {
        scores[entry.key] = score / (matches + 1);
      }
    }

    // Sort by score and take top N
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(maxResults)
        .map(
          (e) =>
              Intent(type: e.key, confidence: (e.value / 2.0).clamp(0.0, 1.0)),
        )
        .toList();
  }

  /// Check if text is a question
  static bool isQuestion(String text) {
    final normalized = Preprocessor.normalize(text);

    // Turkish question words
    final trQuestionWords = [
      'mi',
      'mı',
      'mu',
      'mü',
      'ne ',
      'nasıl',
      'neden',
      'niçin',
      'kim',
      'nerede',
      'hangi',
      'kaç',
    ];
    // English question words
    final enQuestionWords = [
      'what',
      'how',
      'why',
      'when',
      'where',
      'who',
      'which',
      'whose',
      'whom',
      'can',
      'could',
      'would',
      'should',
      'do',
      'does',
      'did',
      'is',
      'are',
      'was',
      'were',
      'will',
    ];

    // Check for question mark
    if (text.contains('?')) return true;

    // Check for question words at start
    for (final word in [...trQuestionWords, ...enQuestionWords]) {
      if (normalized.startsWith(word) || normalized.contains(' $word ')) {
        return true;
      }
    }

    return false;
  }

  /// Check if text is a command
  static bool isCommand(String text) {
    final normalized = Preprocessor.normalize(text);

    // Turkish command verbs (imperative)
    final trCommands = [
      'kur',
      'ayarla',
      'yaz',
      'ekle',
      'sil',
      'düzenle',
      'aç',
      'kapat',
      'göster',
      'bul',
      'ara',
      'hatırlat',
      'kaydet',
      'oluştur',
    ];
    // English command verbs
    final enCommands = [
      'set',
      'create',
      'add',
      'delete',
      'remove',
      'edit',
      'open',
      'close',
      'show',
      'find',
      'search',
      'remind',
      'save',
      'write',
      'make',
    ];

    for (final cmd in [...trCommands, ...enCommands]) {
      if (normalized.contains(cmd)) {
        return true;
      }
    }

    return false;
  }
}
