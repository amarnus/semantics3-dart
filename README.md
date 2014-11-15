# Semantics3 API Dart SDK

## Usage

```dart
import 'package:semantics3/lib/semantics3.dart' as semantics3;
	
// Set your credentials.
const String apiKey = "SEM3xxxxxxxxxxxxxxxxxxxxxxxxx",
  apiSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";

// Build and run a query.
var sem3 = new semantics3.Products(apiKey, apiSecret);
sem3.productsField('cat_id', 13658)
  .productsField('brand', 'Toshiba')
  .productsField('model', 'Satellite')
  .getProducts().then((List products) {
  	print(products);
  })
  .catchError((e) {
	print(e.getMessage()['message']);
	print(e);
  }, test: (e) => e is semantics3.ProductsException);
```
      
## Author

Amarnath Ravikumar <amar@semantics3.com>