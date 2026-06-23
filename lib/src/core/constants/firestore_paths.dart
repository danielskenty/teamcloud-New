class FirestorePaths {
  static const tenants = 'tenants';

  static String tenantDoc(String tenantId) => '$tenants/$tenantId';
  static String tenantBranches(String tenantId) => '$tenants/$tenantId/branches';
  static String tenantUsers(String tenantId) => '$tenants/$tenantId/users';
  static String tenantProducts(String tenantId) => '$tenants/$tenantId/products';
  static String tenantCategories(String tenantId) => '$tenants/$tenantId/categories';
  static String tenantBrands(String tenantId) => '$tenants/$tenantId/brands';
  static String tenantInventory(String tenantId) => '$tenants/$tenantId/inventory';
  static String tenantSales(String tenantId) => '$tenants/$tenantId/sales';
  static String tenantCustomers(String tenantId) => '$tenants/$tenantId/customers';
  static String tenantSuppliers(String tenantId) => '$tenants/$tenantId/suppliers';
  static String tenantExpenses(String tenantId) => '$tenants/$tenantId/expenses';
  static String tenantPurchases(String tenantId) => '$tenants/$tenantId/purchases';
}
