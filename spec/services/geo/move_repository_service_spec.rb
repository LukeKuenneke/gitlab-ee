require 'spec_helper'

describe Geo::MoveRepositoryService do
  let(:project) { create(:project, :repository) }
  let(:new_path) { project.full_path + '+renamed' }
  let(:full_new_path) { File.join(project.repository_storage_path, new_path) }
  subject { described_class.new(project.id, project.name, project.full_path, new_path) }

  describe '#execute' do
    it 'renames the path' do
      old_path = project.repository.path_to_repo
      expect(File.directory?(old_path)).to be_truthy

      expect(subject.execute).to eq(true)

      expect(File.directory?(old_path)).to be_falsey
      expect(File.directory?("#{full_new_path}.git")).to be_truthy
    end
  end
end
