enum MockServiceCategory {
  coupons,
  hotel,
  ktv,
  bar,
  billiards,
  food,
  delivery,
  flashSale,
  boutique,
  massage,
  flights,
  taxi;

  static MockServiceCategory fromWireName(String value) {
    return values.firstWhere(
      (category) => category.name == value,
      orElse: () => MockServiceCategory.food,
    );
  }
}
