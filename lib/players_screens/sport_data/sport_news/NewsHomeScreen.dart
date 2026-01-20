import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mehran_football_academy/my_components/title_text.dart';
import 'package:mehran_football_academy/players_screens/sport_data/sport_news/services.dart';
import 'package:intl/intl.dart';
import 'new_model.dart';

class Newshomescreen extends StatefulWidget {
  const Newshomescreen({super.key});

  @override
  State<Newshomescreen> createState() => _NewshomescreenState();
}

class _NewshomescreenState extends State<Newshomescreen> {
  List<NewsModel> allArticles = []; // Store all articles (old + new)
  bool isLoadingMore = false; // Track if we're loading more data
  bool isInitialLoading = true; // Track initial loading state

  Future<void> fetchNews({bool isRefresh = false}) async {
    setState(() {
      if (!isRefresh) {
        isInitialLoading = true; // Show loading animation for initial load
      }
    });

    NewsApi newsApi = NewsApi();
    await newsApi.getNews();

    if (isRefresh) {
      // On refresh, only add new articles that aren't already in the list
      final newArticles = newsApi.dataStore.where((newArticle) {
        return !allArticles.any((existingArticle) =>
        existingArticle.title == newArticle.title &&
            existingArticle.content == newArticle.content);
      }).toList();

      setState(() {
        allArticles.insertAll(0, newArticles); // Add new articles at the top
        isInitialLoading = false; // Stop loading animation
      });
    } else {
      // Initial load or load more
      setState(() {
        allArticles.addAll(newsApi.dataStore);
        isLoadingMore = false;
        isInitialLoading = false; // Stop loading animation
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNews(); // Load initial data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.topCenter,
          child: TitleText(text: 'Sport News'),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: isInitialLoading
          ? Center(
        child: Lottie.asset(
          'assets/running.json',
          width: 150, // Moderate size for the Lottie animation
          height: 150,
          fit: BoxFit.contain,
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          await fetchNews(isRefresh: true);
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                itemCount: allArticles.length + (isLoadingMore ? 1 : 0),
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == allArticles.length && isLoadingMore) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final article = allArticles[index];
                  // Format publishedAt timestamp
                  String formattedDate = '';
                  if (article.publishedAt != null) {
                    try {
                      final dateTime = DateTime.parse(article.publishedAt!);
                      formattedDate = DateFormat('MMM d, yyyy, h:mm a').format(dateTime);
                    } catch (e) {
                      formattedDate = 'Unknown date';
                    }
                  } else {
                    formattedDate = 'Unknown date';
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailsScreen(article: article),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              article.urlToImage!,
                              height: 250,
                              width: 400,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text('Failed to load image');
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            article.title!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'RubikMedium',
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Published: $formattedDate',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'RubikRegular',
                              color: Colors.grey,
                            ),
                          ),
                          const Divider(thickness: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsDetailsScreen extends StatelessWidget {
  final NewsModel article;

  const NewsDetailsScreen({super.key, required this.article});

  String _cleanContent(String content) {
    // Remove "[+X chars]" suffix if present
    final match = RegExp(r'\[\+\d+\s*chars\]$').firstMatch(content);
    if (match != null) {
      return content.substring(0, match.start).trim();
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final cleanedContent = _cleanContent(article.content!);
    // Format publishedAt timestamp
    String formattedDate = '';
    if (article.publishedAt != null) {
      try {
        final dateTime = DateTime.parse(article.publishedAt!);
        formattedDate = DateFormat('MMM d, yyyy, h:mm a').format(dateTime);
      } catch (e) {
        formattedDate = 'Unknown date';
      }
    } else {
      formattedDate = 'Unknown date';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                article.urlToImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Failed to load image');
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              article.title!,
              style: const TextStyle(fontFamily: 'RubikMedium', fontSize: 19),
            ),
            const SizedBox(height: 10),
            Text(
              'Author: ${article.author ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.normal, color: Colors.black),
            ),
            const SizedBox(height: 5),
            Text(
              'Published: $formattedDate',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.normal, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              article.description!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              cleanedContent,
              style: const TextStyle(fontSize: 16),
            ),
            if (cleanedContent != article.content!) // Show note if content was truncated
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Note: Full article may be truncated by the source. Visit the original source for complete details.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}