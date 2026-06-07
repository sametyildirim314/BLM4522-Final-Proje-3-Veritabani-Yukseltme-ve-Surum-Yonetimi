# DETAYLI PROJE RAPORU: Veritabanı Yükseltme ve Sürüm Yönetimi

**Ders:** Ağ Tabanlı Paralel Dağıtım Sistemleri  
**Proje No:** 6  
**Veritabanı Ortamı:** Microsoft SQL Server (SSMS)  

---

## 1. Projenin Amacı ve Kapsamı
Bu çalışmanın temel amacı, kurumsal veritabanı sistemlerinde yapılan yapısal değişikliklerin (şema güncellemelerinin) izlenebilirliğini sağlamak ve canlı sistemlerde gerçekleştirilecek sürüm yükseltme (upgrade) operasyonlarını güvenli bir zemine oturtmaktır. Çalışma kapsamında DDL (Data Definition Language) tetikleyicileri ile versiyon kontrolü sağlanmış; `TRANSACTION` mimarisi ile veri kayıpsız geri dönüş (Rollback) senaryoları simüle edilmiştir.

## 2. Mimari ve Uygulama Adımları

### Adım 1: Sürüm Yönetimi ve Şema Değişikliklerinin İzlenmesi
Veritabanı üzerinde kontrolsüz yapılan tablo oluşturma, silme veya yapısal değiştirme işlemlerini takip etmek için sistem seviyesinde bir denetim mekanizması kurulmuştur.
* **Uygulanan Mimari:** `FOR DDL_DATABASE_LEVEL_EVENTS` parametresi ile `trg_SemaDegisiklikTakibi` adında bir DDL Trigger oluşturulmuştur.
* **Loglama:** Herhangi bir `CREATE`, `ALTER` veya `DROP` komutu çalıştırıldığında, trigger anında devreye girerek SQL Server'ın XML tabanlı `EVENTDATA()` fonksiyonundan verileri çekmektedir. İşlemi yapan kullanıcının adı, işlem türü, etkilenen nesnenin adı ve kullanılan T-SQL komutunun birebir kopyası `SemaDegisiklik_Loglari` tablosuna tarih damgasıyla kaydedilmektedir.

### Adım 2: Veritabanı Yükseltme (Upgrade) Planı
Sistemdeki uygulamanın 1.0 sürümünden 2.0 sürümüne geçişini simüle etmek için stratejik bir geçiş planı hazırlanmıştır.
* **Hazırlık:** Sistemde aktif olarak çalıştığı varsayılan `Uygulama_v1` tablosu üzerinden yükseltme işlemi başlatılmıştır.
* **Taşıma Süreci:** Bir `TRANSACTION` (İşlem Bütünlüğü) bloğu açılarak, `Uygulama_v2` şeması oluşturulmuş ve v1 içerisindeki veriler yeni veri tipleriyle uyumlu şekilde v2 tablosuna `INSERT INTO ... SELECT` yöntemiyle taşınmıştır. Ardından eski v1 tablosu bellekten silinmiştir.

### Adım 3: Test ve Geri Dönüş (Rollback) Planı
Canlı sistemlerdeki en büyük risk olan "uyumsuzluk ve çökme" durumlarına karşı kurtarma planı tasarlanmış ve test edilmiştir.
* **Test Simülasyonu:** Yeni v2 şemasının uygulamayla uyumlu olup olmadığını denetlemek için süreç `TRY...CATCH` blokları ile çevrelenmiş ve bir test parametresi (`@TestBasariliMi = 0`) tanımlanmıştır.
* **Rollback İşlemi:** Testin başarısız olması durumunda sistemin çökmesini veya veri kaybını önlemek amacıyla `ROLLBACK TRANSACTION` komutu tetiklenmiştir.
* **Sonuç:** Veritabanı motoru, taşıma ve silme (v1 tablosunu silme) işlemlerini geçersiz saymış ve tüm sistemi işlemi başlattığı mili-saniyeye, yani stabil olan v1 sürümüne geri döndürmüştür.

---

## 3. Sonuç
Bu projeyle, bir veritabanının yapısında meydana gelen tüm evrimsel değişikliklerin "DDL Triggers" kullanılarak kayıt altına alınabileceği kanıtlanmıştır. Ayrıca, kritik sistemlerde sürüm yükseltme operasyonlarının tekil sorgularla değil, mutlaka "Transaction" blokları ve "Rollback" yeteneğiyle tasarlanması gerektiği gösterilmiş; sıfır veri kaybı hedefleyen bir "Felaket / Geri Dönüş" senaryosu başarıyla uygulanmıştır.