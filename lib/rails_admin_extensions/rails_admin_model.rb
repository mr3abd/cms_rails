module RailsAdminModelMethods
  def navigation_label_key(k, weight = 0)
    navigation_label do
      I18n.t("admin.navigation_labels.#{k}")
    end
    if weight
      model_weight(weight, k)
    end
  end

  def model_weight(rel_weight, navigation_label)
    weights = {
        feedbacks: 100,
        home: 200,
        about_us: 300,
        projects: 400,
        partnership: 500,
        brands: 600,
        services: 700,
        media: 800,
        contacts: 900,
        tags: 1000,
        users: 1100,
        settings: 1200,
        pages: 1300,
        assets: 1400
    }
    navigation_label_weight = weights[navigation_label.to_sym]
    computed_weight = navigation_label_weight + rel_weight
    weight computed_weight
  end

end

RailsAdmin::Config::Model.send :include, RailsAdminModelMethods
RailsAdmin::Config::Sections::Base.send :include, RailsAdminModelMethods