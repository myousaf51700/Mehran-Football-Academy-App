import 'dart:convert';
import 'package:http/http.dart' as http;
import 'new_model.dart';

class NewsApi {
  List<NewsModel> dataStore = [];

  Future<void> getNews() async {
    Uri url = Uri.parse(
        "https://newsapi.org/v2/top-headlines?country=us&category=sports&apiKey=da3922ecb93644048e780765587a3573");

    var response = await http.get(url);

    var jsonData = jsonDecode(response.body);

    if (jsonData['status'] == 'ok') {
      jsonData['articles'].forEach((element) {
        if (element['urlToImage'] != null &&
            element['description'] != null &&
            element['author'] != null &&
            element['content'] != null &&
            element['publishedAt'] != null) {
          NewsModel newsModel = NewsModel(
            title: element['title'],
            urlToImage: element['urlToImage'],
            description: element['description'],
            author: element['author'],
            content: element['content'],
            publishedAt: element['publishedAt'],
          );
          dataStore.add(newsModel);
        }
      });
    }
  }
}

class CategoryNews {
  List<NewsModel> dataStore = [];

  Future<void> getNews(String category) async {
    Uri url = Uri.parse(
        "https://newsapi.org/v2/top-headlines?country=us&category=sports&apiKey=da3922ecb93644048e780765587a3573");

    var response = await http.get(url);

    var jsonData = jsonDecode(response.body);

    if (jsonData['status'] == 'ok') {
      jsonData['articles'].forEach((element) {
        if (element['urlToImage'] != null &&
            element['description'] != null &&
            element['author'] != null &&
            element['content'] != null &&
            element['publishedAt'] != null) {
          NewsModel newsModel = NewsModel(
            title: element['title'],
            urlToImage: element['urlToImage'],
            description: element['description'],
            author: element['author'],
            content: element['content'],
            publishedAt: element['publishedAt'],
          );
          dataStore.add(newsModel);
        }
      });
    }
  }
}