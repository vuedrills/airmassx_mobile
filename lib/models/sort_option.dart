/// Sort options for browsing tasks
enum SortOption {
  newestPosted('Newest Posted'),
  mostRelevant('Most Relevant'),
  highestBudget('Highest Budget'),
  lowestBudget('Lowest Budget'),
  endingSoon('Ending Soon');

  final String label;
  const SortOption(this.label);
}
