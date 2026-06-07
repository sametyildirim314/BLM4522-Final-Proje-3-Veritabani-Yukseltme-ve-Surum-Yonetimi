

-- 1. ADIM: VERSİYON LOG TABLOSUNU OLUŞTURMA
-- PDF İsteri: Veritabanı yapısındaki değişikliklerin izlenmesi
-- Sistemde yapılan her türlü tablo/şema değişikliği buraya kaydedilecek.
CREATE TABLE dbo.SemaDegisiklik_Loglari (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    IslemTarihi DATETIME DEFAULT GETDATE(),
    KullaniciAdi NVARCHAR(100),
    IslemTuru NVARCHAR(100),
    NesneAdi NVARCHAR(100),
    TsqlKomutu NVARCHAR(MAX)
);
GO


-- 2. ADIM: DDL TRIGGER (TETİKLEYİCİ) OLUŞTURMA
-- PDF İsteri: DDL Triggers kullanarak şema değişikliklerini takip etme
-- Veritabanı seviyesinde çalışan ve değişiklikleri yakalayan tetikleyici.
CREATE TRIGGER trg_SemaDegisiklikTakibi
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();

    INSERT INTO dbo.SemaDegisiklik_Loglari (KullaniciAdi, IslemTuru, NesneAdi, TsqlKomutu)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)')
    );
END;
GO

-- 3. ADIM: SİSTEMİ TEST ETME (SİMÜLASYON)
-- Şimdi sanki veritabanını yeni bir sürüme yükseltiyormuşuz gibi 
-- yeni bir tablo oluşturalım, değiştirelim ve silelim.
-- A) Yeni tablo oluşturma (CREATE)
CREATE TABLE dbo.YeniSurum_TestTablosu (
    ID INT PRIMARY KEY,
    Aciklama NVARCHAR(50)
);
GO

-- B) Tabloyu değiştirme (ALTER)
ALTER TABLE dbo.YeniSurum_TestTablosu ADD YeniKolon INT;
GO

-- C) Tabloyu silme (DROP)
DROP TABLE dbo.YeniSurum_TestTablosu;
GO

-- 4. ADIM: SÜRÜM YÖNETİMİ RAPORUNU İNCELEME
-- Bakalım tetikleyicimiz arka planda tüm bu işlemleri yakalayıp loglamış mı?
SELECT 
    LogID, 
    IslemTarihi, 
    KullaniciAdi, 
    IslemTuru, 
    NesneAdi, 
    TsqlKomutu 
FROM dbo.SemaDegisiklik_Loglari
ORDER BY IslemTarihi DESC;
GO

-- 5. ADIM: VERİTABANI YÜKSELTME (UPGRADE) HAZIRLIĞI
-------------------------------------------------------
-- PDF İsteri: "Veritabanı Yükseltme Planı"
-- Önce sistemde çalışan eski sürüm (v1) bir tablo ve veri oluşturalım.
CREATE TABLE dbo.Uygulama_v1 (
    ID INT, 
    KullaniciAdi NVARCHAR(50)
);
INSERT INTO dbo.Uygulama_v1 VALUES (1, 'Ahmet Yilmaz'), (2, 'Ayse Kaya');
GO

-- 6. ADIM: YÜKSELTME, TEST VE GERİ DÖNÜŞ (ROLLBACK) SİMÜLASYONU
-- PDF İsteri: "Test ve Geri Dönüş Planı"
-- Güvenli bir yükseltme için süreci TRANSACTION (İşlem Bloğu) içine alıyoruz.

PRINT '--- Sürüm v2.0 Yükseltmesi Başlatılıyor ---';

BEGIN TRY
    BEGIN TRANSACTION SurumYukseltme_Gorevi;
    
    -- 1. Yükseltme İşlemi (v2 tablosunu yaratıp verileri taşıyoruz)
    CREATE TABLE dbo.Uygulama_v2 (
        KullaniciID INT, 
        AdSoyad NVARCHAR(100), 
        GuncellemeTarihi DATETIME DEFAULT GETDATE()
    );
    INSERT INTO dbo.Uygulama_v2 (KullaniciID, AdSoyad) 
    SELECT ID, KullaniciAdi FROM dbo.Uygulama_v1;
    
    -- Eski tabloyu siliyoruz
    DROP TABLE dbo.Uygulama_v1;
    PRINT 'Adım 1: v2 Şeması oluşturuldu ve veriler taşındı.';

    -- 2. Test Aşaması (Simülasyon)
    -- Burada bir test sorgusu çalıştırdığımızı ve uygulamanın v2 şemasıyla UYUMSUZ (hata verdiğini) varsayıyoruz.
    DECLARE @TestBasariliMi BIT = 0; -- 0: Hata Çıktı, 1: Sorunsuz

    IF @TestBasariliMi = 0
    BEGIN
        -- 3. Geri Dönüş (Rollback) Planının Devreye Girmesi
        PRINT 'Adım 2: TEST BAŞARISIZ! Uygulama yeni yapıyla uyumsuz.';
        PRINT 'Adım 3: Acil Geri Dönüş (Rollback) Planı Devreye Giriyor...';
        
        ROLLBACK TRANSACTION SurumYukseltme_Gorevi;
        
        PRINT '--- SONUÇ: Sistem güvenli bir şekilde eski sürüme (v1) geri döndürüldü. ---';
    END
    ELSE
    BEGIN
        COMMIT TRANSACTION SurumYukseltme_Gorevi;
        PRINT '--- SONUÇ: Yükseltme Başarılı, Yeni Sürüm (v2) Yayında. ---';
    END

END TRY
BEGIN CATCH
    -- Sistemsel kritik bir çökme olursa otomatik geri dönüş
    ROLLBACK TRANSACTION SurumYukseltme_Gorevi;
    PRINT 'KRİTİK HATA! Sistem otomatik olarak eski sürüme döndürüldü.';
END CATCH;
GO

-- 7. ADIM: GERİ DÖNÜŞÜN KANITLANMASI
-- Rollback çalıştığı için Uygulama_v2 tablosu hiç var olmamış gibi iptal edildi.
-- Eski Uygulama_v1 tablomuz sapasağlam duruyor.
SELECT * FROM dbo.Uygulama_v1;
GO