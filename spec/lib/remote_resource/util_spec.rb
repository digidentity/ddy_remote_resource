require 'spec_helper'

describe RemoteResource::Util do

  describe '.filter_params' do
    let(:scenarios) do
      [
        { params: '{"account_migration":{"username":"foo","password":"bar"}}', expected_params: '{"account_migration":{"username":"foo","password":[FILTERED]}}' },
        { params: '{"account_migration":{"password":"bar","username":"foo"}}', expected_params: '{"account_migration":{"password":[FILTERED],"username":"foo"}}' },
        { params: '?username=foo&password=bar', expected_params: '?username=foo&password=[FILTERED]' },
        { params: '?password=bar&username=foo', expected_params: '?password=[FILTERED]&username=foo' },
        { params: nil, expected_params: '' }
      ]
    end

    it 'removes sensitive information of the filtered params' do
      aggregate_failures do
        scenarios.each do |scenario|
          result = described_class.filter_params(scenario[:params], filtered_params: ['password'])

          expect(result).to eql scenario[:expected_params]
        end
      end
    end
  end

  describe '.encode_params_to_query' do
    let(:scenarios) do
      [
        { params: nil, expected_query: '' },
        { params: {}, expected_query: '' },
        { params: [], expected_query: '' },
        { params: 'Mies', expected_query: 'Mies' },
        { params: { name: 'Mies' }, expected_query: 'name=Mies' },
        { params: { name: 'Mies', age: 29, famous: true, smart: nil }, expected_query: 'name=Mies&age=29&famous=true&smart=' },
        { params: { page: 5, limit: 15 }, expected_query: 'page=5&limit=15' },
        { params: { labels: [1, '2', 'three'] }, expected_query: 'labels[]=1&labels[]=2&labels[]=three' },
        { params: { page: 5, limit: 15, order: [:created_at, :desc] }, expected_query: 'page=5&limit=15&order[]=created_at&order[]=desc' },
        { params: { page: 5, limit: 15, order: { field: :created_at, direction: :desc } }, expected_query: 'page=5&limit=15&order[field]=created_at&order[direction]=desc' },
        { params: { name: 'Mies', age: 29, famous: true, labels: [1, '2', 'three'], pagination: { page: 5, limit: 15, order: { field: :created_at, direction: :desc } } }, expected_query: 'name=Mies&age=29&famous=true&labels[]=1&labels[]=2&labels[]=three&pagination[page]=5&pagination[limit]=15&pagination[order][field]=created_at&pagination[order][direction]=desc' },
      ]
    end

    it 'encodes the params to a URL-encoded query' do
      aggregate_failures do
        scenarios.each do |scenario|
          result = described_class.encode_params_to_query(scenario[:params])
          query  = CGI.unescape(result)

          expect(query).to eql scenario[:expected_query]
        end
      end
    end
  end

end
