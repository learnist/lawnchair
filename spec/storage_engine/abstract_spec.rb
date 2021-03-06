require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Lawnchair::StorageEngine::Abstract" do
  attr_reader :abstract_store

  before do
    @abstract_store = Lawnchair::StorageEngine::Abstract
  end

  describe ".data_store" do
    it "should be an empty hash" do
      abstract_store.data_store.should == {}
    end
  end

  describe ".fetch" do
    context "when key exists" do
      before do
        abstract_store.data_store["sim"] = "ba"
      end

      it "returns the value from the cache" do
        value = abstract_store.fetch("sim", :raw => true) { "DOESNT MATTER" }
        value.should == "ba"
      end

      it "increments the cache HIT count for this key" do
        abstract_store.fetch("sim", :raw => true) { "DOESNT MATTER" }
        abstract_store.fetch("sim", :raw => true) { "DOESNT MATTER" }
        Lawnchair.redis.hget("HIT", "sim").should == "2"
      end
    end

    context "when key does not exist" do
      before do
        abstract_store.stub!(:exists?).and_return(false)
        abstract_store.data_store["sim"].should be_nil

        class Lawnchair::StorageEngine::Abstract
          def self.set(key, value, options={})
            data_store[key.to_s] = value
          end
        end
      end

      it "computes the value and saves it to the cache" do
        value = abstract_store.fetch("sim", :raw => true) { "ba" }
        abstract_store.data_store["sim"].should == "ba"
      end

      it "increments the cache MISS count for this key" do
        abstract_store.fetch("sim", :raw => true) { "ba" }
        abstract_store.data_store["sim"] = nil
        abstract_store.fetch("sim", :raw => true) { "ba" }
        abstract_store.data_store["sim"] = nil
        abstract_store.fetch("sim", :raw => true) { "ba" }
        Lawnchair.redis.hget("MISS", "sim").should == "3"
      end
    end
  end

  describe ".get" do
    context "when raw is true" do
      it "gets the value in key if it exists" do
        abstract_store.data_store["mu"] = "fasa"
        abstract_store.get("mu", :raw => true).should == "fasa"
      end

      it "returns nil if the key does not exist" do
        abstract_store.data_store["mu"].should be_nil
        abstract_store.get("mu", :raw => true).should be_nil
      end
    end

    context "when raw is false" do
      context "when they key exists" do
        before do
          abstract_store.stub!(:exists?).and_return(true)
        end

        it "gets the value in key if it exists and unmarshalls it" do
          expected_value = "fasa"
          value = Marshal.dump(expected_value)

          abstract_store.data_store["mu"] = value
          abstract_store.get("mu", :raw => false).should == expected_value
        end
      end

      context "when the key does not exist" do
        before do
          abstract_store.stub!(:exists?).and_return(false)
        end

        it "returns nil if the key does not exist" do
          abstract_store.data_store["mu"].should be_nil
          abstract_store.get("mu", :raw => false).should be_nil
        end
      end
    end

    it "raises an exception if no key is given" do
      lambda do
        abstract_store.get("") { 1 }
      end.should raise_error

      lambda do
        abstract_store.get(nil)
      end.should raise_error
    end
  end
end
