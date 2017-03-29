module RailsAdminModelMethods
  def self.configure_navigation_labels
    #self.class_variable_set(:@@_navigation_labels)
    RailsAdmin::Config.navigation_labels
  end
  def navigation_label_key(k, weight = 0)
    navigation_label do
      I18n.t("admin.navigation_labels.#{k}")
    end
    if weight
      model_weight(weight, k)
    end
  end

  def model_weight(rel_weight, navigation_label)
    weights = RailsAdmin::Config.navigation_labels
    navigation_label_weight = weights[navigation_label.to_sym]
    if navigation_label_weight
      computed_weight = navigation_label_weight + rel_weight
      weight computed_weight
    else
      weight rel_weight
    end

  end

end



RailsAdmin::Config::Model.send :include, RailsAdminModelMethods
#RailsAdmin::Config::Sections::Base.send :include, RailsAdminModelMethods