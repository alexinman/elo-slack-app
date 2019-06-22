class ApplicationViewModel
  def initialize(data)
    @data = data
  end

  def as_json(options = nil)
    @data.as_json(options)
  end

  class << self
    def list(rel, options={})
      rel = sort(rel, options)
      data = paginate(rel, options, &method(:item_summary))
      new(data)
    end

    def details_for(item)
      new(item_details(item))
    end

    private

    def model_class
      raise NotImplementedError
    end

    def item_summary(item)
      item.attributes
    end

    def item_details(item)
      item.attributes
    end

    def sort(rel, options = {})
      direction = options[:direction] == 'asc' ? :asc : :desc
      sql_order = Array.wrap(sql_order(options)) + [model_class.arel_table[:id]]
      rel.order(*sql_order.map(&direction))
    end

    def sql_order(_options = {})
      raise NotImplementedError
    end

    def paginate(rel, options = {}, &mapping_blk)
      page = [options[:page].to_i, 1].max
      per_page = [1, (options[:per_page] || 10).to_i, 100].sort.second
      item_count = rel.count
      page_count = (item_count / per_page) + ((item_count % per_page == 0) ? 0 : 1)
      paged_rel = rel.paginate(page: page, per_page: per_page)
      {
          :page => page,
          :per_page => per_page,
          :page_count => page_count,
          :item_count => item_count,
          :items => block_given? ? paged_rel.map(&mapping_blk) : paged_rel
      }
    end
  end
end