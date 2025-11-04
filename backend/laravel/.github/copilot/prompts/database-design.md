# Prompt: Database Design

## Purpose
Design and optimize database schemas, relationships, migrations, and queries for Laravel applications following best practices.

## When to Use
- Creating new database tables
- Designing relationships between models
- Optimizing existing schema
- Planning indexes and constraints
- Data migration strategies

---

## Prompt Template

```
I need to design a database schema for:

**Feature**: [What feature needs database support]
**Requirements**:
- [List functional requirements]
- [Data that needs to be stored]
- [Expected query patterns]
- [Performance requirements]

**Relationships**:
- [Describe relationships between entities]

Please provide:
1. **Entity-Relationship diagram**: Visual representation
2. **Table schemas**: Column definitions with types
3. **Migrations**: Laravel migration files
4. **Models**: Eloquent model relationships
5. **Indexes**: Performance optimization
6. **Constraints**: Data integrity rules
7. **Seeder**: Sample data for testing
```

---

## Example 1: E-Commerce Product System

### Input:
```
I need to design a database schema for:

**Feature**: E-commerce product catalog with variants

**Requirements**:
- Products can have multiple variants (size, color)
- Track inventory per variant
- Support product categories (nested)
- Products can have multiple images
- Price history tracking
- SEO-friendly slugs

**Relationships**:
- Products belong to categories
- Products have many variants
- Variants have inventory records
- Products have many images
- Categories can have sub-categories
```

### Expected Output:

## 📊 Entity-Relationship Diagram

```
┌─────────────────┐         ┌─────────────────┐
│   categories    │◄───────┤    products     │
│                 │         │                 │
│ - id            │         │ - id            │
│ - parent_id  ◄──┼─┐       │ - category_id   │
│ - name          │ │       │ - name          │
│ - slug          │ │       │ - slug          │
└─────────────────┘ │       │ - description   │
                    └───────┤ - base_price    │
                            │ - status        │
                            └────┬────────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
             ┌──────▼──────┐ ┌───▼────────┐ ┌▼────────────┐
             │   variants  │ │   images   │ │ price_hist. │
             │             │ │            │ │             │
             │ - id        │ │ - id       │ │ - id        │
             │ - product_id│ │ - product  │ │ - product   │
             │ - sku       │ │ - path     │ │ - price     │
             │ - price     │ │ - order    │ │ - effective │
             └──────┬──────┘ └────────────┘ └─────────────┘
                    │
             ┌──────▼──────┐
             │  inventory  │
             │             │
             │ - id        │
             │ - variant_id│
             │ - quantity  │
             │ - warehouse │
             └─────────────┘
```

---

## 🗄️ Database Schema

### 1. Categories Table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parent_id')->nullable()
                ->constrained('categories')
                ->onDelete('cascade');
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->integer('order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index(['parent_id', 'is_active']);
            $table->index('slug');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
```

### 2. Products Table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')
                ->constrained()
                ->onDelete('restrict');
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->text('specifications')->nullable(); // JSON
            $table->decimal('base_price', 10, 2);
            $table->string('sku')->unique();
            $table->enum('status', ['draft', 'active', 'archived'])
                ->default('draft');
            $table->boolean('is_featured')->default(false);
            $table->integer('view_count')->default(0);

            // SEO fields
            $table->string('meta_title')->nullable();
            $table->text('meta_description')->nullable();
            $table->text('meta_keywords')->nullable();

            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index(['category_id', 'status']);
            $table->index('slug');
            $table->index('is_featured');
            $table->index('created_at');

            // Full-text search
            $table->fullText(['name', 'description']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
```

### 3. Product Variants Table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_variants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')
                ->constrained()
                ->onDelete('cascade');
            $table->string('sku')->unique();
            $table->string('name'); // e.g., "Large / Red"
            $table->json('attributes'); // {"size": "L", "color": "red"}
            $table->decimal('price', 10, 2);
            $table->decimal('compare_at_price', 10, 2)->nullable();
            $table->integer('weight')->nullable(); // in grams
            $table->boolean('is_default')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            // Indexes
            $table->index(['product_id', 'is_active']);
            $table->index('sku');
            $table->unique(['product_id', 'attributes']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_variants');
    }
};
```

### 4. Inventory Table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_variant_id')
                ->constrained()
                ->onDelete('cascade');
            $table->string('warehouse_location')->default('default');
            $table->integer('quantity')->default(0);
            $table->integer('reserved_quantity')->default(0);
            $table->integer('reorder_point')->default(10);
            $table->integer('reorder_quantity')->default(50);
            $table->timestamp('last_restocked_at')->nullable();
            $table->timestamps();

            // Indexes
            $table->index(['product_variant_id', 'warehouse_location']);
            $table->unique(['product_variant_id', 'warehouse_location']);

            // Check constraint (MySQL 8.0.16+)
            $table->check('quantity >= 0');
            $table->check('reserved_quantity >= 0');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory');
    }
};
```

### 5. Product Images Table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')
                ->constrained()
                ->onDelete('cascade');
            $table->string('path');
            $table->string('disk')->default('public');
            $table->string('alt_text')->nullable();
            $table->integer('order')->default(0);
            $table->boolean('is_primary')->default(false);
            $table->timestamps();

            // Indexes
            $table->index(['product_id', 'order']);
            $table->index(['product_id', 'is_primary']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_images');
    }
};
```

### 6. Price History Table

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('price_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_variant_id')
                ->constrained()
                ->onDelete('cascade');
            $table->decimal('old_price', 10, 2);
            $table->decimal('new_price', 10, 2);
            $table->timestamp('effective_from');
            $table->timestamp('effective_until')->nullable();
            $table->string('reason')->nullable();
            $table->foreignId('changed_by')
                ->nullable()
                ->constrained('users')
                ->onDelete('set null');
            $table->timestamps();

            // Indexes
            $table->index(['product_variant_id', 'effective_from']);
            $table->index('effective_from');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('price_history');
    }
};
```

---

## 📦 Eloquent Models

### Category Model

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'parent_id',
        'name',
        'slug',
        'description',
        'order',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'order' => 'integer',
    ];

    /**
     * Parent category (self-referential).
     */
    public function parent(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    /**
     * Child categories.
     */
    public function children(): HasMany
    {
        return $this->hasMany(Category::class, 'parent_id')
            ->orderBy('order');
    }

    /**
     * Products in this category.
     */
    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    /**
     * Get full category path (e.g., "Electronics > Phones > iPhone").
     */
    public function getFullPathAttribute(): string
    {
        $path = [$this->name];
        $parent = $this->parent;

        while ($parent) {
            array_unshift($path, $parent->name);
            $parent = $parent->parent;
        }

        return implode(' > ', $path);
    }
}
```

### Product Model

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Laravel\Scout\Searchable; // Optional: for full-text search

class Product extends Model
{
    use SoftDeletes, Searchable;

    protected $fillable = [
        'category_id',
        'name',
        'slug',
        'description',
        'specifications',
        'base_price',
        'sku',
        'status',
        'is_featured',
        'meta_title',
        'meta_description',
        'meta_keywords',
    ];

    protected $casts = [
        'base_price' => 'decimal:2',
        'specifications' => 'array',
        'is_featured' => 'boolean',
        'view_count' => 'integer',
    ];

    /**
     * Category this product belongs to.
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Product variants.
     */
    public function variants(): HasMany
    {
        return $this->hasMany(ProductVariant::class);
    }

    /**
     * Active variants only.
     */
    public function activeVariants(): HasMany
    {
        return $this->variants()->where('is_active', true);
    }

    /**
     * Product images.
     */
    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class)->orderBy('order');
    }

    /**
     * Primary image.
     */
    public function primaryImage()
    {
        return $this->hasOne(ProductImage::class)
            ->where('is_primary', true);
    }

    /**
     * Get default variant.
     */
    public function defaultVariant()
    {
        return $this->hasOne(ProductVariant::class)
            ->where('is_default', true);
    }

    /**
     * Check if product is in stock.
     */
    public function getInStockAttribute(): bool
    {
        return $this->variants()
            ->whereHas('inventory', function ($query) {
                $query->where('quantity', '>', 0);
            })
            ->exists();
    }
}
```

### ProductVariant Model

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ProductVariant extends Model
{
    protected $fillable = [
        'product_id',
        'sku',
        'name',
        'attributes',
        'price',
        'compare_at_price',
        'weight',
        'is_default',
        'is_active',
    ];

    protected $casts = [
        'attributes' => 'array',
        'price' => 'decimal:2',
        'compare_at_price' => 'decimal:2',
        'weight' => 'integer',
        'is_default' => 'boolean',
        'is_active' => 'boolean',
    ];

    /**
     * Product this variant belongs to.
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Inventory records.
     */
    public function inventory(): HasMany
    {
        return $this->hasMany(Inventory::class);
    }

    /**
     * Total inventory across all warehouses.
     */
    public function getTotalInventoryAttribute(): int
    {
        return $this->inventory()->sum('quantity');
    }

    /**
     * Available inventory (not reserved).
     */
    public function getAvailableInventoryAttribute(): int
    {
        return $this->inventory()
            ->get()
            ->sum(fn($inv) => $inv->quantity - $inv->reserved_quantity);
    }

    /**
     * Price history.
     */
    public function priceHistory(): HasMany
    {
        return $this->hasMany(PriceHistory::class);
    }
}
```

### Inventory Model

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Inventory extends Model
{
    protected $table = 'inventory';

    protected $fillable = [
        'product_variant_id',
        'warehouse_location',
        'quantity',
        'reserved_quantity',
        'reorder_point',
        'reorder_quantity',
        'last_restocked_at',
    ];

    protected $casts = [
        'quantity' => 'integer',
        'reserved_quantity' => 'integer',
        'reorder_point' => 'integer',
        'reorder_quantity' => 'integer',
        'last_restocked_at' => 'datetime',
    ];

    /**
     * Variant this inventory belongs to.
     */
    public function variant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class, 'product_variant_id');
    }

    /**
     * Available quantity (not reserved).
     */
    public function getAvailableQuantityAttribute(): int
    {
        return max(0, $this->quantity - $this->reserved_quantity);
    }

    /**
     * Check if reorder is needed.
     */
    public function needsReorder(): bool
    {
        return $this->available_quantity <= $this->reorder_point;
    }
}
```

---

## 🌱 Database Seeder

```php
<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\ProductImage;
use App\Models\Inventory;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        // Create categories
        $electronics = Category::create([
            'name' => 'Electronics',
            'slug' => 'electronics',
            'is_active' => true,
        ]);

        $phones = Category::create([
            'parent_id' => $electronics->id,
            'name' => 'Smartphones',
            'slug' => 'smartphones',
            'is_active' => true,
        ]);

        // Create product
        $product = Product::create([
            'category_id' => $phones->id,
            'name' => 'iPhone 15 Pro',
            'slug' => 'iphone-15-pro',
            'description' => 'Latest iPhone with A17 Pro chip',
            'specifications' => [
                'processor' => 'A17 Pro',
                'ram' => '8GB',
                'display' => '6.1 inch OLED',
            ],
            'base_price' => 999.00,
            'sku' => 'IPHONE-15-PRO',
            'status' => 'active',
            'is_featured' => true,
        ]);

        // Create variants
        $colors = ['Black', 'White', 'Blue'];
        $storages = ['128GB', '256GB', '512GB'];
        $prices = [999, 1099, 1299];

        foreach ($colors as $color) {
            foreach ($storages as $index => $storage) {
                $variant = ProductVariant::create([
                    'product_id' => $product->id,
                    'sku' => "IPHONE-15-PRO-{$storage}-{$color}",
                    'name' => "{$storage} / {$color}",
                    'attributes' => [
                        'color' => $color,
                        'storage' => $storage,
                    ],
                    'price' => $prices[$index],
                    'is_default' => $color === 'Black' && $storage === '128GB',
                    'is_active' => true,
                ]);

                // Create inventory
                Inventory::create([
                    'product_variant_id' => $variant->id,
                    'warehouse_location' => 'main',
                    'quantity' => rand(10, 100),
                    'reserved_quantity' => 0,
                    'reorder_point' => 10,
                    'reorder_quantity' => 50,
                ]);
            }
        }

        // Create images
        for ($i = 1; $i <= 4; $i++) {
            ProductImage::create([
                'product_id' => $product->id,
                'path' => "products/iphone-15-pro-{$i}.jpg",
                'alt_text' => "iPhone 15 Pro - Image {$i}",
                'order' => $i,
                'is_primary' => $i === 1,
            ]);
        }
    }
}
```

---

## 🎯 Usage Examples

### Query Products with All Relationships

```php
$products = Product::with([
        'category',
        'variants.inventory',
        'images',
        'primaryImage',
    ])
    ->where('status', 'active')
    ->paginate(12);
```

### Get Products in Stock

```php
$inStockProducts = Product::whereHas('variants.inventory', function ($query) {
        $query->whereRaw('quantity > reserved_quantity');
    })
    ->get();
```

### Reserve Inventory

```php
DB::transaction(function () use ($variant, $quantity) {
    $inventory = $variant->inventory()
        ->where('warehouse_location', 'main')
        ->lockForUpdate()
        ->first();

    if ($inventory->available_quantity >= $quantity) {
        $inventory->increment('reserved_quantity', $quantity);
        return true;
    }

    throw new InsufficientInventoryException();
});
```

---

## Related Prompts

- `performance-optimization.md` - Optimize database queries
- `code-explanation.md` - Understand database relationships
- `testing-strategy.md` - Test database operations
