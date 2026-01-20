class NewsModel {
  String? title;
  String? description;
  String? urlToImage;
  String? author;
  String? content;
  String? publishedAt;

  NewsModel({
    this.title,
    this.description,
    this.urlToImage,
    this.author,
    this.content,
    this.publishedAt,
  });
}

class CategoryModel {
  String? categoryName;

  CategoryModel({
    this.categoryName,
  });
}