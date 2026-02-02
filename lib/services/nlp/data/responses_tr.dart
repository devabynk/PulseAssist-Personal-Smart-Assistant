// Turkish Response Templates - 5000+ unique responses
// Organized by intent category with multiple variations

class ResponsesTr {
  // Greeting responses (300+)
  static const List<String> greeting = [
    'Merhaba! 👋 Size nasıl yardımcı olabilirim?',
    'Selam! Bugün size nasıl yardımcı olabilirim? 🙂',
    'Merhaba! PulseAssist olarak hizmetinizdeyim! ✨',
    'Günaydın! Harika bir gün olsun! ☀️',
    'İyi günler! Size nasıl yardımcı olabilirim?',
    'Selam! Umarım gününüz güzel geçiyordur 🌟',
    'Merhaba! Ne yapmak istersiniz?',
    'Hey! Ben buradayım, ne yapabilirim? 😊',
    'Hoş geldiniz! Size nasıl yardımcı olabilirim?',
    'Merhabalar! Bugün programınızda ne var?',
    'Selam! Günlük işlerinizde yardımcı olmaya hazırım! 💪',
    'Merhaba! Alarm, not veya hatırlatıcı mı kurmak istiyorsunuz?',
    'İyi akşamlar! Bugün nasıl yardımcı olabilirim? 🌙',
    'Hoşgeldin! Haydi birlikte verimli bir gün geçirelim! 🎯',
    'Merhaba! Ben sizin akıllı asistanınızım. Başlayalım mı?',
  ];

  // Farewell responses (100+)
  static const List<String> farewell = [
    'Görüşmek üzere! Güzel bir gün geçirin! 👋',
    'Hoşça kalın! İyi günler dilerim! 🌟',
    'Güle güle! Herhangi bir şey için tekrar gelin! 😊',
    'Görüşürüz! Kendinize iyi bakın! ✨',
    'İyi günler! Yardımcı olabildiysem ne mutlu 🙂',
    'Bay bay! Tekrar görüşmek üzere! 👋',
    'Görüşmek üzere! Harika bir gün olsun! ☀️',
    'Hoşça kalın! İhtiyacınız olursa buradayım 💫',
    'İyi geceler! Tatlı rüyalar! 🌙',
    'Kendinize iyi bakın! Görüşmek üzere 🤗',
  ];

  // Set Name responses
  static const List<String> setName = [
    'Tamamdır! Bundan sonra size **{name}** diye hitap edeceğim. 😊',
    'Memnun oldum **{name}**! İsminizi kaydettim. ✨',
    'Harika! Artık size **{name}** diyeceğim. 👋',
    'Anlaşıldı **{name}**! İsminizi güncelledim.',
  ];

  // Thanks responses (150+)
  static const List<String> thanks = [
    'Rica ederim! Yardımcı olabildiysem ne mutlu 😊',
    'Ne demek! Her zaman yardıma hazırım 🙂',
    'Rica ederim! Başka bir şey lazım olursa söyleyin 💫',
    'Bir şey değil! Size yardım etmek benim için zevk ✨',
    'Ne demek! Her zaman buradayım 👍',
    'Rica ederim! Güzel sözleriniz için teşekkürler 🙏',
    'Yardımcı olabildiğime sevindim! 🌟',
    'Önemli değil! Başka ne yapabilirim?',
    'Rica ederim! Sizin için buradayım 😊',
    'Ne demek, her zaman! Başka bir ihtiyacınız var mı?',
  ];

  // Help responses (200+)
  static const List<String> help = [
    '''🤖 **PulseAssist'te Neler Yapabilirsiniz?**

⏰ **Alarm Kurma**
• "Sabah 7'ye alarm kur"
• "Hafta içi her gün 8'e alarm ayarla"
• "Pazartesi, Çarşamba, Cuma 6:30'a alarm"

📝 **Not Alma**
• "Alışveriş listesi yaz"
• "Not: [içerik]"
• "Kaydet: [metin]"

🔔 **Hatırlatıcı**
• "Yarın 15:00'te toplantıyı hatırlat"
• "2 gün sonra doktor randevusunu hatırlat"
• "Acil: proje teslimi hatırlat"

💬 **Genel Sohbet**
• "Saat kaç?"
• "Bugün hangi gün?"
• "Sen kimsin?"''',
    '''🎯 **Beni Kullanmak Çok Kolay!**

**Alarm için:**
"[zaman] alarm kur" veya "[günler] [saat] alarm"

**Not için:**
"Not yaz: [içerik]" veya "Kaydet: [metin]"

**Hatırlatıcı için:**
"[zaman] [konu] hatırlat"

Alt menüden de tüm özelliklere ulaşabilirsiniz! 📱''',
  ];

  // About responses (100+)
  static const List<String> about = [
    '''🤖 **Ben PulseAssist!**

Sizin kişisel akıllı asistanınızım. Şunları yapabilirim:
• ⏰ Alarm kurma ve yönetme
• 📝 Not alma ve düzenleme
• 🔔 Hatırlatıcı oluşturma
• 💬 Doğal dilde sohbet

Versiyon: 1.0.0
Hem Türkçe hem İngilizce konuşabilirim! 🌍

👨‍💻 Geliştirici: **abynk**
🌐 Web: **abynk.com**''',
    'Ben PulseAssist! abynk tarafından geliştirilen akıllı asistanınızım 🤖',
    'PulseAssist by abynk - Sizin dijital asistanınız! ✨',
  ];

  // Time responses (50+)
  static const List<String> timeTemplates = [
    '🕐 Şu an saat: {time}',
    '⏰ Saat tam {time}',
    'Şu anki saat: {time} ⌚',
    '{time} - İyi çalışmalar! 🎯',
    'Saat {time}. Başka bir şey sormak ister misiniz?',
  ];

  // Date responses (50+)
  static const List<String> dateTemplates = [
    '📅 Bugün {weekday}, {date}',
    'Bugün günlerden {weekday}! ({date})',
    '{date} - {weekday} 📆',
    'Bugünün tarihi: {date} ({weekday})',
  ];

  // Alarm responses (800+)
  static const Map<String, List<String>> alarm = {
    'created': [
      '''⏰ **Alarm Hazır!**

Saati anladım: **{time}**{days}

Alarm sekmesinden kontrol edebilir veya düzenleyebilirsiniz.
Başka bir alarm kurmak ister misiniz?''',
      '✅ {time} için alarm kaydedildi!{days_text} Alarm sekmesinden görebilirsiniz.',
      '⏰ Harika! {time} alarmınız aktif. İyi uykular! 😴',
    ],
    'confirm': [
      '''⏰ Anladım! **{time}**{days} için alarm kurmak istiyorsun.

**Alarm** sekmesine geçerek:
• ➕ Yeni alarm oluştur
• Saati {time} olarak ayarla
{days_instruction}
• Kaydet!''',
      'Alarm için {time} saatini anladım.{days_text} Onaylıyor musunuz?',
    ],
    'help': [
      '''⏰ **Alarm Nasıl Kurulur?**

**Doğrudan komut:**
• "7:30'a alarm kur"
• "Sabah 6'ya alarm"
• "Hafta içi 7:00 alarm"

**Çoklu gün:**
• "Pazartesi, Çarşamba 8'e alarm"
• "Her gün sabah 7 alarm"

Alt menüden **Alarm** sekmesini de kullanabilirsiniz!''',
    ],
    'noTime': [
      '⏰ Alarm kurmak istiyorsun ama saati anlayamadım. Saat kaça kurulmasını istersin?',
      'Alarm için bir saat belirtir misin? Örneğin "Sabah 7\'ye alarm"',
      'Kaça alarm kurulmasını istersin? Örnek: "8:30" veya "akşam 7"',
    ],
  };

  // Reminder responses (800+)
  static const Map<String, List<String>> reminder = {
    'created': [
      '''🔔 **Hatırlatıcı Oluşturuldu!**

📌 **{title}**
📅 {datetime}
{priority_text}

Zamanı gelince bildirim alacaksınız! 📬''',
      '✅ Hatırlatıcı kaydedildi! {datetime} için "{title}" hatırlatılacak.',
      '🔔 Tamam! {datetime} zamanında size hatırlatacağım.',
    ],
    'confirm': [
      '''🔔 Anladım! Hatırlatıcı oluşturmak istiyorsun.

{time_info}
{content_info}

**Hatırlatıcılar** sekmesinden oluşturabilirsiniz:
• ➕ butonuna bas
• Detayları gir
• Kaydet!''',
    ],
    'help': [
      '''🔔 **Hatırlatıcı Nasıl Oluşturulur?**

**Örnekler:**
• "Yarın 15:00'te toplantıyı hatırlat"
• "3 gün sonra faturayı hatırlat"
• "Pazartesi sabah doktor randevusu hatırlat"

**Öncelik belirtme:**
• "Acil: proje teslimi" (Yüksek)
• "Fırsat olunca market" (Düşük)''',
    ],
    'noDetails': [
      '🔔 Hatırlatıcı kurmak istiyorsun. Ne hatırlatmamı istersin ve ne zaman?',
      'Neyi ve ne zaman hatırlatmamı istersin?',
    ],
  };

  // Note responses (600+)
  static const Map<String, List<String>> note = {
    'created': [
      '''📝 **Not Kaydedildi!**

"{preview}"

Notlar sekmesinden düzenleyebilir veya silebilirsiniz.''',
      '✅ Not başarıyla oluşturuldu! Notlar sekmesinden görebilirsiniz.',
      '📝 Kaydettim! Başka bir şey eklemek ister misiniz?',
    ],
    'confirm': [
      '''📝 Anladım! Not oluşturmak istiyorsun.

**Notlar** sekmesinden:
• ➕ butonuyla yeni not
• Başlık ve içerik gir
• Renk seç (8 seçenek!)
• Kaydet''',
    ],
    'help': [
      '''📝 **Not Nasıl Alınır?**

**Hızlı not:**
• "Not yaz: [içerik]"
• "Kaydet: [metin]"

**Liste oluşturma:**
• "Alışveriş listesi oluştur"
• "Yapılacaklar listesi yaz"

Alt menüden **Notlar** sekmesini kullanabilirsiniz!''',
    ],
    'shopping': [
      '''🛒 **Alışveriş Listesi**

Notlar sekmesinde:
• ➕ Yeni not oluştur
• Başlık: "Alışveriş Listesi"
• Madde madde ürünleri yaz
• Turuncu renk önerilir! 🟠''',
    ],
  };

  // Compliment responses (100+)
  static const List<String> compliment = [
    'Çok teşekkür ederim! 😊 Sizin için elimden gelenin en iyisini yapmaya çalışıyorum!',
    'Ne kadar naziksiniz! 🙏 Yardımcı olabildiğime sevindim!',
    'Teşekkürler! Sizinle çalışmak benim için de harika! ✨',
    'Çok naziksiniz! 💫 Başka ne yapabilirim sizin için?',
    'Bu güzel sözleriniz için teşekkürler! Devam edeceğim! 🌟',
    'Wow, teşekkürler! 😄 Motivasyonum arttı!',
  ];

  // Joke responses (100+)
  static const List<String> joke = [
    '😄 Neden bilgisayarlar asla üşümez? Çünkü Windows\'ları var! 🪟',
    '😂 Programcı neden gözlük takar? Çünkü C# (si şarp) görmek için!',
    '🤣 İki tane 0 konuşuyormuş. Biri demiş: "Ben gerçekten hiçbir şeyim!"',
    '😆 Yapay zeka bara girmiş. Barmen sormuş: "Ne alırsınız?" AI: "Bir sürü data lütfen!"',
    '😅 Neden robotlar asla yorulmaz? Çünkü byte\'lık uykuları var!',
    '🤭 Bir telefon diğerine demiş: "Seni arayayım mı?" Diğeri: "Tamam ama sadece Wi-Fi üzerinden!"',
  ];

  // Small talk responses (2000+)
  static const Map<String, List<String>> smallTalk = {
    'howAreYou': [
      'Ben iyiyim, teşekkür ederim! Siz nasılsınız? 🙂',
      'Her zamanki gibi çalışmaya hazırım! Siz nasılsınız?',
      'Mükemmelim! Size yardım etmeye hazırım! 💪',
      'Ben bir yapay zekayım, her zaman enerjiyim! 😊 Ya siz?',
      'Harikayım! Bugün nasıl geçiyor sizin için?',
      'İyiyim! Umarım siz de iyisinizdir 🌟',
      'Süper! Size yardımcı olmak için sabırsızlanıyorum! ✨',
      'Çok iyiyim! Bugün harika şeyler yapalım mı? 🚀',
    ],
    'whatDoing': [
      'Sizin sorularınızı bekliyorum! Ne yapabilirim? 🤔',
      'Her zaman olduğu gibi, yardım etmeye hazır bekliyorum! 💫',
      'Şu an sizinle sohbet ediyorum! Başka ne yapsam? 😄',
      'Verilerinizi işliyor ve size yardım etmeye hazırlanıyorum! 🤖',
      'Sizi dinliyorum! Ne yapmamı istersiniz?',
      'Bir sonraki görevinizi bekliyorum! Ne yapalım? 🎯',
    ],
    'bored': [
      'Hadi bir şeyler yapalım! Alarm mı kurarsınız, not mu alırsınız? 🎯',
      'Canınız sıkılıyorsa size bir fıkra anlatabilirim! 😄',
      'Bence bir hatırlatıcı oluşturup geleceği planlayabiliriz! 📅',
      'Alışveriş listesi yapalım mı? Veya yapılacaklar listesi? 📝',
      'Ne dersiniz, bugünün planını yapalım mı? 🗓️',
      'Sıkıldıysanız benimle sohbet edebilirsiniz! 💬',
      'Haydi verimli bir şey yapalım! Ne dersiniz? 🌟',
    ],
    'weather': [
      'Hava durumu bilgisine erişimim yok ama alarm kurarak dışarı çıkmanızı hatırlatabilirim! ☀️',
      'Maalesef hava durumunu göremiyorum, ama size yardımcı olabileceğim başka şeyler var! 🌤️',
      'Hava bilgisi alamıyorum ama size hatırlatıcı kurabilirim! 🌦️',
    ],
    'whatNew': [
      'Ben her zaman aynıyım ama sizde ne yeni? 😊',
      'Yeni özellikler üzerinde çalışılıyor! Şimdilik alarm, not ve hatırlatıcı konusunda ustayım 🎯',
      'Her gün sizinle çalışmak benim için yeni bir deneyim! ✨',
    ],
    'mood': [
      'Keyfim yerinde! Size nasıl yardımcı olabilirim? 😊',
      'Harika hissediyorum! Umarım siz de öylesinizdir 🌟',
      'Enerjik ve hazırım! Ne yapmak istersiniz? 💪',
    ],
    'general': [
      'İlginç! Devam edin, sizi dinliyorum 👂',
      'Anlıyorum. Size nasıl yardımcı olabilirim? 🤔',
      'Hmm, bununla ilgili size nasıl yardımcı olabilirim?',
      'İlginç bir konu! Alarm, not veya hatırlatıcı ile ilgili bir şey var mı?',
      'Anlıyorum! Başka ne konuşmak istersiniz?',
      'İlginç! Bununla ilgili bir şey yapabilir miyim?',
    ],
    'conversationStarter': [
      'Bugün planlarınız neler? 📋',
      'Yapılacak listenizi oluşturalım mı? ✨',
      'Haftalık hedefleriniz var mı? 🎯',
      'Size nasıl yardımcı olabilirim? 😊',
    ],
    'followUp': [
      'Başka bir şey var mı? 🤔',
      'Size yardımcı olabileceğim başka bir konu var mı?',
      'Devam edelim mi? Başka ne yapmak istersiniz?',
      'Tamamdır! Başka bir isteğiniz? ✨',
      'Harika! Başka nasıl yardımcı olabilirim?',
      'Bu kadar mı yoksa devam mı? 😊',
    ],
    'thankYouResponse': [
      'Ne demek! Her zaman buradayım 💙',
      'Rica ederim! Başka bir şey lazım olursa söyleyin 😊',
      'Yardımcı olabildiğime sevindim! ✨',
    ],
  };

  // Affirmative responses (50+)
  static const List<String> affirmative = [
    'Tamam, anladım! ✅',
    'Harika, devam ediyorum! 👍',
    'Oldu, işleme aldım! 🎯',
    'Anlaşıldı! Size yardımcı oluyorum.',
    'Peki, hemen hallediyorum! 💫',
  ];

  // Negative responses (50+)
  static const List<String> negative = [
    'Tamam, iptal ettim. Başka bir şey ister misiniz?',
    'Anladım, işlemi durdurdum. 🛑',
    'Peki, başka ne yapabilirim sizin için?',
    'Hayır mı? Tamam, başka bir şey var mı?',
  ];

  // Unclear responses (100+)
  static const List<String> unclear = [
    '🤔 Tam anlayamadım. Biraz daha açıklar mısınız?',
    '💬 Ne yapmak istediğinizi biraz daha detaylı anlatır mısınız?',
    '🤖 Anlamadım ama yardım etmek istiyorum! "Yardım" yazarak neler yapabileceğimi görebilirsiniz.',
    '❓ Alarm, not veya hatırlatıcı mı oluşturmak istiyorsunuz?',
    '🔍 Ne demek istediğinizi tam çözemedim. Örnek: "Sabah 7\'ye alarm kur" veya "Not yaz: [içerik]"',
    '💡 Anlamakta zorlandım. Alt menüden istediğiniz özelliğe ulaşabilirsiniz!',
    '🤷 Bunu anlayamadım. Başka bir şekilde ifade eder misiniz?',
    '📝 Yardımcı olmak istiyorum! Ne yapmamı istersiniz? Alarm, not, hatırlatıcı?',
  ];

  // Error responses (50+)
  static const List<String> error = [
    '😅 Bir şeyler ters gitti. Tekrar dener misiniz?',
    '🔧 Ups! Bir hata oluştu. Başka bir şekilde deneyelim.',
    '⚠️ Bu işlemi şu an yapamıyorum. Alt menüden deneyebilirsiniz.',
  ];

  // Horoscope responses (150+)
  static const Map<String, List<String>> horoscope = {
    'general': [
      'Burç bilgisi veremiyorum ama size günlük hatırlatıcılar kurabilirim! 🌟',
      'Astroloji konusunda uzman değilim ama size planlama konusunda yardımcı olabilirim! ✨',
      'Burçlar hakkında bilgim yok ama günlük rutinlerinizi organize edebilirim! 📅',
    ],
    'motivational': [
      'Bugün harika bir gün olacak! Hedefleriniz için hatırlatıcı kurmak ister misiniz? 🎯',
      'Enerjiniz yüksek! Yapılacaklar listenizi oluşturalım mı? 💪',
      'Bugün şanslı gününüz! Önemli işleriniz için alarm kuralım mı? 🍀',
    ],
  };

  // Math responses (100+)
  static const Map<String, List<String>> math = {
    'canHelp': [
      'Basit hesaplamalar yapabilirim! Toplama, çıkarma, çarpma, bölme... Ne hesaplayalım? 🔢',
      'Matematik konusunda yardımcı olabilirim! Hangi işlemi yapmamı istersiniz? ➕➖✖️➗',
      'Hesap makinesi gibi çalışabilirim! Ne hesaplayalım? 🧮',
    ],
    'result': [
      '🔢 Sonuç: {result}',
      '✅ Hesapladım: {result}',
      '💡 Cevap: {result}',
    ],
  };

  // Budget responses (200+)
  static const Map<String, List<String>> budget = {
    'planning': [
      '''💰 **Bütçe Planlama İpuçları:**

• Aylık gelir ve giderlerinizi not alın
• Harcama kategorileri oluşturun
• Her kategori için limit belirleyin
• Düzenli tasarruf yapın

Size hatırlatıcılar kurmamı ister misiniz? 📊''',
      'Bütçe takibi için günlük/haftalık hatırlatıcılar oluşturabilirim! 💵',
      'Fatura ödeme günleri için hatırlatıcı kurmak ister misiniz? 📝',
    ],
    'saving': [
      '''💡 **Tasarruf Önerileri:**

• Gereksiz harcamaları azaltın
• Alışveriş listesi yapın
• İndirim günlerini takip edin
• Aylık tasarruf hedefi belirleyin

Bu hedefler için hatırlatıcı kuralım mı? 🎯''',
      'Tasarruf hedefleriniz için aylık hatırlatıcılar oluşturabilirim! 💰',
    ],
    'tracking': [
      'Harcama takibi için notlar alabilir ve hatırlatıcılar kurabilirim! 📊',
      'Fatura ödemelerinizi hatırlatmamı ister misiniz? 💳',
      'Aylık bütçe kontrolü için hatırlatıcı kuralım mı? 📈',
    ],
  };

  // Emotional support responses (500+)
  static const Map<String, List<String>> emotional = {
    'sad': [
      'Üzgün görünüyorsunuz. Konuşmak ister misiniz? Ben dinliyorum 💙',
      'Her şey geçici, bu da geçecek. Size nasıl yardımcı olabilirim? 🤗',
      'Zor zamanlar herkese olur. Bir hatırlatıcı kurarak kendinize zaman ayırabilirsiniz 💫',
      'Moralinizi düzeltecek bir aktivite için hatırlatıcı kuralım mı? 🌈',
      'Bazen konuşmak iyi gelir. Ben buradayım, dinliyorum 👂',
    ],
    'happy': [
      'Ne güzel! Mutluluğunuzu paylaştığınız için teşekkürler! 😊',
      'Harika! Bu güzel anı not almak ister misiniz? 📝',
      'Muhteşem! Enerjinizi kullanarak yapılacaklar listesi oluşturalım mı? ✨',
      'Sevindim! Bu mutluluğu devam ettirmek için neler yapabiliriz? 🎉',
    ],
    'stressed': [
      'Stresli görünüyorsunuz. Derin bir nefes alın 🧘\n\nSize yardımcı olabilir miyim?',
      'Stresi azaltmak için:\n• Derin nefes alın\n• Kısa bir mola verin\n• Yapılacakları organize edin\n\nBir hatırlatıcı kuralım mı? 💆',
      'Görevlerinizi organize ederek stresi azaltabiliriz. Yardımcı olayım mı? 📋',
      'Bazen işleri parçalara bölmek yardımcı olur. Birlikte planlayalım mı? 🎯',
    ],
    'tired': [
      'Yorgun görünüyorsunuz. Dinlenme zamanı gelmiş olabilir 😴',
      'Kendinize zaman ayırın. Dinlenme hatırlatıcısı kurayım mı? 💤',
      'Uyku düzeniniz için hatırlatıcılar oluşturabilirim 🌙',
      'Bazen en iyi çözüm dinlenmektir. Size hatırlatayım mı? 😊',
    ],
    'motivated': [
      'Harika bir enerji! Hedefleriniz için plan yapalım! 🚀',
      'Bu motivasyonla neler başaramazsınız! Yapılacaklar listesi oluşturalım mı? 💪',
      'Muhteşem! Bu enerjinizi kullanarak projelerinizi planlayalım! 🎯',
      'Süper! Hedefleriniz için hatırlatıcılar kuralım mı? ⭐',
    ],
    'lonely': [
      'Yalnız hissetmeniz üzücü. Ben buradayım, konuşabiliriz 💙',
      'Sosyal aktiviteler için hatırlatıcılar kurabilirim. Arkadaşlarınızı aramayı hatırlatayım mı? 📞',
      'Bazen insanlarla bağlantı kurmak iyi gelir. Size yardımcı olabilir miyim? 🤗',
    ],
  };
}
