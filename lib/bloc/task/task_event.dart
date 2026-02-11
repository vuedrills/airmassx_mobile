abstract class TaskEvent {
  const TaskEvent();
}

class TaskLoadAll extends TaskEvent {
  const TaskLoadAll();
}

class TaskLoadMyTasks extends TaskEvent {
  const TaskLoadMyTasks();
}

class TaskLoadById extends TaskEvent {
  final String taskId;
  
  const TaskLoadById(this.taskId);
}

class TaskFilterByCategory extends TaskEvent {
  final String? category; // null means all categories
  
  const TaskFilterByCategory(this.category);
}

class TaskFilterByPriceRange extends TaskEvent {
  final double? minPrice;
  final double? maxPrice;
  
  const TaskFilterByPriceRange({this.minPrice, this.maxPrice});
}

class TaskSearchByQuery extends TaskEvent {
  final String query;
  
  const TaskSearchByQuery(this.query);
}

class TaskApplyFilters extends TaskEvent {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? searchQuery;
  
  const TaskApplyFilters({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
  });
}
class TaskLoadActive extends TaskEvent {
  const TaskLoadActive();
}

class TaskLoadPendingReviews extends TaskEvent {
  const TaskLoadPendingReviews();
}

class TaskComplete extends TaskEvent {
  final String taskId;
  const TaskComplete(this.taskId);
}
class TaskCancel extends TaskEvent {
  final String taskId;
  const TaskCancel(this.taskId);
}
