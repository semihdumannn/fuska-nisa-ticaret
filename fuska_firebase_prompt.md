# Proje Bağlamı

Çok markalı içecek ürünleri satan bir mobil uygulama geliştiriyorum.  
Markalar arasında Fuska (su), Freşa (soda), Nazlı (bardak su), Capri-Sun (meyve suyu) gibi firmalar var.  
Backend olarak **Firebase Firestore** kullanıyorum.

---

# Firestore Koleksiyon Yapısı

## `/brands/{brandId}`
Marka bilgilerini tutar.

```
{
  name: string,          // "Fuska", "Freşa", "Capri-Sun"
  slug: string,          // "fuska", "fresa", "capri-sun"
  logoUrl: string,       // Firebase Storage URL
  description: string,
  isActive: boolean,
  order: number          // listede sıralama
}
```

---

## `/categories/{categoryId}`
Ürün kategorileri. `parentId` ile hiyerarşik yapı kurulabilir (örn. "Su > Damacana").

```
{
  name: string,          // "Su", "Soda", "Meyve Suyu", "Bardak Su"
  slug: string,
  parentId: string|null, // alt kategori için üst kategorinin ID'si
  icon: string,          // emoji veya icon adı
  order: number,
  isActive: boolean
}
```

---

## `/products/{productId}`
Ürün kartı. Görseller ve açıklama burada tutulur; fiyat ve stok **variants** koleksiyonundadır.

```
{
  brandId: string,       // → /brands/{brandId}
  categoryId: string,    // → /categories/{categoryId}
  name: string,          // "Fuska Doğal Kaynak Suyu"
  description: string,
  imageUrl: string,      // kapak görseli
  imageUrls: string[],   // galeri
  tags: string[],        // ["glutensiz", "vegan", "sifir-seker"]
  isActive: boolean,
  isFeatured: boolean,   // öne çıkan ürün
  order: number,
  createdAt: timestamp
}
```

**Gerekli Firestore index'ler:**
- `brandId` (asc) + `isActive` (asc)
- `categoryId` (asc) + `isActive` (asc)
- `categoryId` (asc) + `isFeatured` (asc)

---

## `/variants/{variantId}`
Her ürünün boyut / ambalaj varyantları. Her varyant ayrı bir dokümandır.

```
{
  productId: string,       // → /products/{productId}
  name: string,            // "0.5L", "1.5L", "19L", "Koli (12 adet)"
  sku: string,             // dahili stok kodu
  barcode: string,         // EAN barkod
  price: number,           // TL, normal fiyat
  salePrice: number|null,  // indirimli fiyat (null = indirim yok)
  unit: string,            // "adet", "koli", "palet"
  stock: number,
  minOrderQty: number,
  maxOrderQty: number,
  packageQty: number,      // koli içi adet
  palletPackageQty: number, // palet içi koli adedi
  palletWeight: number,    // kg
  isActive: boolean
}
```

**Gerekli Firestore index'ler:**
- `productId` (asc) + `isActive` (asc)
- `isActive` (asc) + `price` (asc)

---

## `/customers/{customerId}`
Müşteri / bayi profili. Adresler gömülü array olarak tutulur.

```
{
  name: string,
  phone: string,
  email: string,
  addresses: [           // gömülü
    {
      label: string,     // "İş Yeri", "Depo"
      line1: string,
      city: string,
      district: string,
      postalCode: string
    }
  ],
  isActive: boolean,
  createdAt: timestamp
}
```

---

## `/orders/{orderId}`
Sipariş. `items` dizisi sipariş anındaki ürün bilgilerini **denormalize** olarak içerir;
fiyat veya ürün adı sonradan değişse bile eski sipariş bozulmaz.

```
{
  customerId: string,     // → /customers/{customerId}
  status: string,         // "pending" | "confirmed" | "shipped" | "delivered" | "cancelled"
  items: [                // gömülü — denormalize
    {
      variantId: string,  // referans (sorgusuz, sadece iz için)
      productId: string,
      name: string,       // sipariş anındaki ürün adı (kopya)
      brandName: string,  // sipariş anındaki marka adı (kopya)
      quantity: number,
      unitPrice: number,  // sipariş anındaki birim fiyat (kopya)
      totalPrice: number  // quantity × unitPrice
    }
  ],
  subtotal: number,
  total: number,          // KDV dahil
  address: {              // gömülü — anlık kopya
    label: string,
    line1: string,
    city: string,
    district: string
  },
  notes: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Gerekli Firestore index'ler:**
- `customerId` (asc) + `createdAt` (desc)
- `status` (asc) + `createdAt` (desc)

---

# Önemli Tasarım Kararları

1. **Fiyat ve stok `variants`'ta.** Bir ürünün birden fazla boyutu (0.5L, 1.5L, 5L) olabilir;
   her boyut ayrı stok ve fiyat taşır.

2. **Siparişler denormalize.** `orders.items[]` içinde ürün adı ve fiyat anında kopyalanır.
   Firestore'da join olmadığı için bu zorunludur.

3. **Kategoriler hiyerarşik.** `parentId` null ise üst kategori, dolu ise alt kategoridir.
   Maksimum 2 seviye önerilir (üst → alt).

4. **Composite index'ler zorunlu.** `where` + `orderBy` kombinasyonları için
   Firebase Console'dan veya `firestore.indexes.json` ile index tanımlanmalıdır.

---

# Teknoloji Yığını

- **Frontend:** React Native (Expo)
- **Backend:** Firebase Firestore + Firebase Storage + Firebase Auth
- **Dil:** TypeScript

---

# Talimatlar

Bundan sonra bu projeyle ilgili sorduğum her soruda:
- Yukarıdaki koleksiyon yapısına ve alan isimlerine sadık kal
- Kod örneklerini **TypeScript** ile yaz
- Firestore sorguları için `firebase/firestore` modüler SDK (v9+) kullan
- Gerektiğinde index uyarısı ver
- Denormalizasyon veya yapısal bir değişiklik önerirsen nedenini açıkla
