require 'spec_helper'
describe 'nubis_apache' do
  context 'with default values for all parameters' do
    it { should contain_class('nubis_apache') }
  end
end
