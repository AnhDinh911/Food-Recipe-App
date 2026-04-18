import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_recipe_app/core/app_theme.dart';
import 'package:food_recipe_app/data/recipe_repository.dart';
import 'package:food_recipe_app/models/recipe.dart';
import 'package:food_recipe_app/models/recipe_comment.dart';
import 'package:food_recipe_app/screens/user_profile_screen.dart';
import 'package:food_recipe_app/widgets/common_widgets.dart';
import 'package:food_recipe_app/widgets/detail_stat_chip.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  Recipe? _recipe;
  bool _isLoading = true;
  bool _isSaveLoading = false;
  bool _isCommentLoading = false;
  bool _isSaved = false;
  String? _errorMessage;
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipe = await RecipeRepository.instance.fetchRecipeById(widget.recipeId);
      if (!mounted) return;

      if (recipe == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Recipe not found';
        });
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final isSaved = userId != null
          ? await RecipeRepository.instance.isRecipeSaved(
              userId: userId,
              recipeId: recipe.id,
            )
          : false;

      if (!mounted) return;
      setState(() {
        _recipe = recipe;
        _isSaved = isSaved;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load recipe';
      });
    }
  }

  Future<void> _toggleSavedRecipe() async {
    final recipe = _recipe;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (recipe == null) return;
    if (userId == null) {
      _showMessage('Please sign in to save recipes.');
      return;
    }

    setState(() => _isSaveLoading = true);
    try {
      await RecipeRepository.instance.toggleSavedRecipe(
        userId: userId,
        recipe: recipe,
      );
      if (!mounted) return;
      setState(() => _isSaved = !_isSaved);
      _showMessage(_isSaved ? 'Recipe saved.' : 'Recipe removed from saved list.');
    } catch (e) {
      _showMessage('Could not update saved recipes: $e');
    } finally {
      if (mounted) setState(() => _isSaveLoading = false);
    }
  }

  Future<void> _submitComment({String? parentCommentId}) async {
    final controller = parentCommentId == null ? _commentController : _replyController;
    final message = controller.text.trim();

    if (message.isEmpty) {
      _showMessage('Write a comment before posting.');
      return;
    }

    setState(() => _isCommentLoading = true);
    try {
      await RecipeRepository.instance.addComment(
        recipeId: widget.recipeId,
        message: message,
        parentCommentId: parentCommentId,
      );
      controller.clear();
      if (!mounted) return;
      setState(() => _replyingToCommentId = null);
    } catch (e) {
      _showMessage('$e');
    } finally {
      if (mounted) setState(() => _isCommentLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _recipe == null) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage ?? 'Recipe not found'),
        ),
      );
    }

    final recipe = _recipe!;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _loadRecipe,
        child: StreamBuilder<List<RecipeComment>>(
          stream: RecipeRepository.instance.watchComments(recipe.id),
          builder: (context, snapshot) {
            final comments = snapshot.data ?? const <RecipeComment>[];
            final threads = _buildCommentThreads(comments);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        child: RecipeNetworkImage(
                          imageUrl: recipe.imageUrl,
                          height: 320,
                        ),
                      ),
                      Positioned(
                        top: 48,
                        left: 16,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 48,
                        right: 16,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                          child: IconButton(
                            onPressed: _isSaveLoading ? null : _toggleSavedRecipe,
                            icon: Icon(
                              _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                recipe.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.rating.toStringAsFixed(1),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          recipe.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: DetailStatChip(
                                icon: Icons.access_time_rounded,
                                value: '${recipe.durationMinutes}',
                                label: 'Mins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DetailStatChip(
                                icon: Icons.local_fire_department_outlined,
                                value: '${recipe.calories}',
                                label: 'Cal',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DetailStatChip(
                                icon: Icons.bar_chart_rounded,
                                value: recipe.difficulty,
                                label: 'Level',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DetailStatChip(
                                icon: Icons.place_outlined,
                                value: recipe.origin,
                                label: 'Origin',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _CreatorSection(
                          recipe: recipe,
                          onTap: recipe.creatorId.trim().isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => UserProfileScreen(
                                        userId: recipe.creatorId,
                                      ),
                                    ),
                                  );
                                },
                          isSaved: _isSaved,
                          isSaveLoading: _isSaveLoading,
                          onSaveTap: _toggleSavedRecipe,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ingredients',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...recipe.ingredients.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Icon(Icons.circle, size: 6, color: Colors.orange),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Steps',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(recipe.steps.length, (index) {
                          final stepNumber = index + 1;
                          final stepText = recipe.steps[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$stepNumber',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    stepText,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        _CommentComposer(
                          controller: _commentController,
                          onSubmit: () => _submitComment(),
                          isLoading: _isCommentLoading,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              'Comments',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${comments.length}',
                              style: TextStyle(
                                color: AppColors.textDark.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (snapshot.hasError)
                          _CommentSectionMessage(
                            text: 'Comments could not be loaded right now.',
                          )
                        else if (threads.isEmpty)
                          _CommentSectionMessage(
                            text: 'Be the first to comment on this recipe.',
                          )
                        else
                          ...threads.map(
                            (thread) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CommentThreadCard(
                                comment: thread.parent,
                                replies: thread.replies,
                                isReplying: _replyingToCommentId == thread.parent.id,
                                replyController: _replyController,
                                isLoading: _isCommentLoading,
                                onReplyTap: () {
                                  setState(() {
                                    _replyingToCommentId =
                                        _replyingToCommentId == thread.parent.id
                                            ? null
                                            : thread.parent.id;
                                  });
                                  if (_replyingToCommentId == null) {
                                    _replyController.clear();
                                  }
                                },
                                onSubmitReply: () => _submitComment(
                                  parentCommentId: thread.parent.id,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<_CommentThread> _buildCommentThreads(List<RecipeComment> comments) {
    final rootComments = comments.where((comment) => !comment.isReply).toList(growable: true);
    final replyMap = <String, List<RecipeComment>>{};

    for (final comment in comments.where((item) => item.isReply)) {
      final parentId = comment.parentCommentId;
      if (parentId == null || parentId.isEmpty) continue;
      replyMap.putIfAbsent(parentId, () => <RecipeComment>[]).add(comment);
    }

    return rootComments
        .map(
          (comment) => _CommentThread(
            parent: comment,
            replies: replyMap[comment.id] ?? const [],
          ),
        )
        .toList(growable: false);
  }
}

class _CreatorSection extends StatelessWidget {
  const _CreatorSection({
    required this.recipe,
    required this.isSaved,
    required this.isSaveLoading,
    required this.onSaveTap,
    this.onTap,
  });

  final Recipe recipe;
  final bool isSaved;
  final bool isSaveLoading;
  final VoidCallback onSaveTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recipe Creator',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                UserAvatar(
                  name: recipe.creatorName,
                  photoUrl: recipe.creatorPhotoUrl,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.creatorName.trim().isNotEmpty
                            ? recipe.creatorName
                            : 'Chef',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.createdAt != null
                            ? 'Shared ${_formatDate(recipe.createdAt!)}'
                            : 'Community recipe creator',
                        style: TextStyle(
                          color: AppColors.textDark.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryGreen,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaveLoading ? null : onSaveTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(
                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              ),
              label: Text(isSaved ? 'Saved to your list' : 'Save this recipe'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.onSubmit,
    required this.isLoading,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment Section',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your thoughts about this recipe',
              filled: true,
              fillColor: AppColors.primaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(isLoading ? 'Posting...' : 'Post Comment'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentThread {
  const _CommentThread({
    required this.parent,
    required this.replies,
  });

  final RecipeComment parent;
  final List<RecipeComment> replies;
}

class _CommentThreadCard extends StatelessWidget {
  const _CommentThreadCard({
    required this.comment,
    required this.replies,
    required this.isReplying,
    required this.replyController,
    required this.isLoading,
    required this.onReplyTap,
    required this.onSubmitReply,
  });

  final RecipeComment comment;
  final List<RecipeComment> replies;
  final bool isReplying;
  final TextEditingController replyController;
  final bool isLoading;
  final VoidCallback onReplyTap;
  final VoidCallback onSubmitReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentBubble(comment: comment),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onReplyTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primaryGreen,
            ),
            icon: const Icon(Icons.reply_rounded, size: 18),
            label: Text(isReplying ? 'Cancel reply' : 'Reply'),
          ),
          if (isReplying) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write a reply',
                      filled: true,
                      fillColor: AppColors.primaryBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: isLoading ? null : onSubmitReply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  ),
                  child: Text(isLoading ? '...' : 'Send'),
                ),
              ],
            ),
          ],
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.primaryGreen.withValues(alpha: 0.22),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: replies
                    .map(
                      (reply) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CommentBubble(
                          comment: reply,
                          compact: true,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    this.compact = false,
  });

  final RecipeComment comment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          name: comment.authorName,
          photoUrl: comment.authorPhotoUrl,
          radius: compact ? 16 : 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.authorName,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (comment.createdAt != null)
                    Text(
                      _commentDate(comment.createdAt!),
                      style: TextStyle(
                        color: AppColors.textDark.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.message,
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.88),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _commentDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _CommentSectionMessage extends StatelessWidget {
  const _CommentSectionMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textDark.withValues(alpha: 0.65),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
