# Proje 6: Veritabanı Yükseltme ve Sürüm Yönetimi

Bu proje, **Ağ Tabanlı Paralel Dağıtım Sistemleri** dersi kapsamında, canlı veritabanı sistemlerindeki şema değişikliklerinin (versiyon farklılıklarının) izlenmesi ve güvenli bir yükseltme (upgrade) mimarisinin kurulması amacıyla geliştirilmiştir. 

🎥 **[Proje Sunum ve Uygulama Videosunu İzlemek İçin Tıklayın](https://youtu.be/QAPWkkhdxHg)**

## 🎯 Proje Hedefleri
- **Sürüm Yönetimi (Şema İzleme):** Veritabanı seviyesinde `DDL Triggers` kurarak tablolar üzerindeki tüm `CREATE`, `ALTER` ve `DROP` işlemlerini kayıt altına almak.
- **Yükseltme Planı:** Sistemin eski sürümünden (v1) yeni sürümüne (v2) geçiş stratejisini simüle etmek.
- **Test ve Geri Dönüş Planı:** Yükseltme sırasında oluşabilecek veri uyumsuzluklarına karşı, veri kaybını önleyen "Rollback" (Geri Dönüş) senaryosunu devreye sokmak.

## 🛠️ Teknik Senaryo
Çalışma iki ana bölümden oluşmaktadır. İlk bölümde, veritabanına gizli bir izleme mekanizması (DDL Trigger) kurularak arka planda yapılan tüm yapısal değişiklikler (kimin yaptığı, saat kaçta yaptığı ve hangi T-SQL kodunu kullandığı) loglanmaktadır. İkinci bölümde ise, `TRANSACTION` blokları kullanılarak bir v2 yükseltmesi başlatılmakta; testin başarısız olduğu simüle edilerek sistem güvenli bir şekilde `ROLLBACK` ile eski v1 sürümüne geri döndürülmektedir.

## 🚀 Başlatma Talimatları
1. Microsoft SQL Server Management Studio (SSMS) üzerinden ilgili veritabanına bağlanın.
2. Script içerisindeki **1, 2, 3 ve 4. Adımları** çalıştırarak `DDL Trigger` mekanizmasının kurulumunu ve şema değişikliklerinin nasıl loglandığını (Sürüm Yönetimi) inceleyin.
3. **5, 6 ve 7. Adımları** çalıştırarak Yükseltme, Test ve Geri Dönüş (Rollback) simülasyonunu test edin.