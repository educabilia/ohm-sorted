### 0.3.4

 - Fix `SortedSet#size` when using slicing

### 0.3.3

 - Fix broken `SortedSet#each` behavior

### 0.3.2

 - You can now use `SortedSet#reverse` to query in reverse order.

   For instance:

   ```
   Post.sorted_find(:created_at).reverse.between(Time.now - 10, Time.now)
   ```

 - `SortedSet#each` now returns an Enumerator when called without a block

### 0.3.1

 - Return correct set size for ranged sets

### 0.3.0

 - Simplify query API

### 0.2.1

 - Fix empty? method for SortedSet in Ohm legacy

### 0.2.0

 - Major refactor of the plugin internals
 - Change syntax for declaring sorted indices

### 0.1.0

 - Initial release
