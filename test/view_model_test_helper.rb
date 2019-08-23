def setup_basic_view_model_tests(sort_orders, optional_parameters)
  context 'basic view model tests' do
    context '#list' do
      setup do
        @items = 15.times.map { create_object }.sort_by(&:created_at)
        5.times { create_object_different_team }
      end

      context 'with required parameters' do
        should 'return only results matching required parameters' do
          expected = {
              page: 1,
              per_page: 10,
              page_count: 2,
              item_count: 15,
              items: @items.first(10).map(&method(:summary))
          }
          assert_equivalent expected, view_model.list(required_parameters).as_json.with_indifferent_access
        end

        context 'pagination' do
          context 'page' do
            should 'return specified page' do
              expected = {
                  page: 2,
                  per_page: 10,
                  page_count: 2,
                  item_count: 15,
                  items: @items.last(5).map(&method(:summary))
              }
              parameters = required_parameters.merge({page: 2})
              assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
            end

            context 'negative page' do
              should 'return results for page 1' do
                expected = {
                    page: 1,
                    per_page: 10,
                    page_count: 2,
                    item_count: 15,
                    items: @items.first(10).map(&method(:summary))
                }
                parameters = required_parameters.merge(page: -1)
                assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
              end
            end
          end

          context 'per_page' do
            should 'return specified number' do
              expected = {
                  page: 1,
                  per_page: 5,
                  page_count: 3,
                  item_count: 15,
                  items: @items.first(5).map(&method(:summary))
              }
              parameters = required_parameters.merge({per_page: 5})
              assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
            end

            context 'negative per_page' do
              should 'return per_page 1' do
                expected = {
                    page: 1,
                    per_page: 1,
                    page_count: 15,
                    item_count: 15,
                    items: @items.first(1).map(&method(:summary))
                }
                parameters = required_parameters.merge(per_page: -1)
                assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
              end
            end

            context 'very large per_page' do
              should 'return per_page 100' do
                expected = {
                    page: 1,
                    per_page: 100,
                    page_count: 1,
                    item_count: 15,
                    items: @items.map(&method(:summary))
                }
                parameters = required_parameters.merge(per_page: 101)
                assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
              end
            end
          end

          context 'page and per_page' do
            should 'return specific number and page' do
              page2 = [@items[5], @items[6], @items[7], @items[8], @items[9]]
              expected = {
                  page: 2,
                  per_page: 5,
                  page_count: 3,
                  item_count: 15,
                  items: page2.map(&method(:summary))
              }
              parameters = required_parameters.merge({page: 2, per_page: 5})
              assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
            end
          end
        end

        context 'sorting' do
          context 'order' do
            sort_orders.each do |order|
              context order do
                setup do
                  update_values(order)
                end

                should 'return results ordered by specified order' do
                  expected = {
                      page: 1,
                      per_page: 10,
                      page_count: 2,
                      item_count: 15,
                      items: @items.sort_by(&order).first(10).map(&method(:summary))
                  }
                  parameters = required_parameters.merge({order: order})
                  assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
                end

                context 'all values same' do
                  setup do
                    update_values(order, same_value: true)
                  end

                  should 'order by id' do
                    expected = {
                        page: 1,
                        per_page: 10,
                        page_count: 2,
                        item_count: 15,
                        items: @items.sort_by(&:id).first(10).map(&method(:summary))
                    }
                    parameters = required_parameters.merge({order: order})
                    assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
                  end
                end
              end
            end

            context 'invalid order' do
              should 'return results sorted by default' do
                expected = {
                    page: 1,
                    per_page: 10,
                    page_count: 2,
                    item_count: 15,
                    items: @items.first(10).map(&method(:summary))
                }
                parameters = required_parameters.merge({order: :foobar})
                assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
              end
            end
          end

          context 'direction' do
            context 'asc' do
              should 'return results in ascending order' do
                expected = {
                    page: 1,
                    per_page: 10,
                    page_count: 2,
                    item_count: 15,
                    items: @items.first(10).map(&method(:summary))
                }
                parameters = required_parameters.merge({direction: :asc})
                assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
              end
            end

            context 'desc' do
              should 'return results in descending order' do
                expected = {
                    page: 1,
                    per_page: 10,
                    page_count: 2,
                    item_count: 15,
                    items: @items.reverse.first(10).map(&method(:summary))
                }
                parameters = required_parameters.merge({direction: :desc})
                assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
              end
            end

            context 'invalid direction' do
              should 'return results in ascending order' do
                expected = {
                    page: 1,
                    per_page: 10,
                    page_count: 2,
                    item_count: 15,
                    items: @items.first(10).map(&method(:summary))
                }
                parameters = required_parameters.merge({direction: :foobar})
                assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
              end
            end
          end

          context 'order and direction' do
            sort_orders.each do |order|
              context order do
                %w(asc desc).each do |direction|
                  context direction do
                    setup do
                      update_values(order)
                      @items.sort_by!(&order)
                      @items.reverse! if direction == 'desc'
                    end

                    should 'return results ordered by specified order and direction' do
                      expected = {
                          page: 1,
                          per_page: 10,
                          page_count: 2,
                          item_count: 15,
                          items: @items.first(10).map(&method(:summary))
                      }
                      parameters = required_parameters.merge({order: order, direction: direction})
                      assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
                    end
                  end
                end
              end
            end
          end
        end

        optional_parameters.each do |parameter|
          context "optional_parameter:#{parameter}" do
            setup do
              update_values(parameter)
            end

            should 'return only item matching parameter' do
              item = @items.first
              expected = {
                  page: 1,
                  per_page: 10,
                  page_count: 1,
                  item_count: 1,
                  items: [summary(item)]
              }
              parameters = required_parameters.merge({parameter => item.send(parameter)})
              assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
            end
          end
        end
      end

      context 'without required parameters' do
        should 'return no results' do
          expected = {
              page: 1,
              per_page: 10,
              page_count: 0,
              item_count: 0,
              items: []
          }
          assert_equivalent expected, view_model.list.as_json.with_indifferent_access
        end
      end
    end

    context '#details_for' do
      setup do
        @item = create_object
      end

      should 'return details' do
        assert_equivalent details(@item), view_model.details_for(@item).as_json.with_indifferent_access
      end
    end
  end
end

def update_values(attribute, same_value: false)
  @items.shuffle.each_with_index do |item, index|
    type = model.columns_hash[attribute.to_s].type
    index = 0 if same_value
    value = case type
            when :sting
              index.to_s
            when :datetime
              Time.at(index)
            else
              index
            end
    item.update_attribute(attribute, value)
  end
end

def summary(item)
  item.attributes.as_json
end

def details(item)
  item.attributes.as_json
end

def required_parameters
  {
      slack_team_id: 'SLACKTEAMID'
  }
end

def view_model
  raise NotImplementedError
end

def model
  raise NotImplementedError
end

def model_sym
  model.name.underscore.to_sym
end

def basic_object_attributes(slack_team_id = nil)
  {slack_team_id: slack_team_id || 'SLACKTEAMID'}
end

def create_object
  FactoryBot.create(model_sym, basic_object_attributes)
end

def create_object_different_team
  FactoryBot.create(model_sym, basic_object_attributes('DIFFERENT'))
end