class PapersModel {
  String? id;
  String? name;
  String? category;
  String? pageFilePath;
  String? createdAt;
  String? updatedAt;

  PapersModel(
      {this.id,
      this.name,
      this.category,
      this.pageFilePath,
      this.createdAt,
      this.updatedAt});

  PapersModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    category = json['category'];
    pageFilePath = json['page_file_path'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['category'] = category;
    data['page_file_path'] = pageFilePath;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
