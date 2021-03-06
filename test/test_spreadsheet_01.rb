require 'test/unit'
require 'goodsheet'

class TestSpreadsheet_01 < Test::Unit::TestCase

  def setup
    filepath = File.dirname(__FILE__) + "/fixtures/ss_01.xls"
    @ss = Goodsheet::Spreadsheet.new(filepath)
  end

  def test_sheets
    assert_equal(%w(Sheet1 Sheet2 Sheet3 Sheet4 Sheet5), @ss.sheets)
  end

  def test_failed_sheet_selection
    assert_raise Goodsheet::SheetNotFoundError do
      @ss.sheet(14)
    end
    assert_raise Goodsheet::SheetNotFoundError do
      @ss.sheet("Sheet999")
    end
  end

  def test_sheet_selection_and_name
    # by default the first sheet will be selected
    assert_equal("Sheet1", @ss.name)    

    @ss.sheet(0)
    assert_equal("Sheet1", @ss.name)    

    @ss.sheet(1)
    assert_equal("Sheet2", @ss.name)    

    @ss.sheet(2)
    assert_equal("Sheet3", @ss.name)    

    @ss.sheet(3)
    assert_equal("Sheet4", @ss.name)    

    @ss.sheet(4)
    assert_equal("Sheet5", @ss.name)    
  end

  def test_get_header_wo_options
    @ss.sheet(0)
    assert_equal(%w(A B C D), @ss.get_header)
  end

  def test_get_header_w_options
    @ss.sheet("Sheet3", :header_row => 1)
    assert_equal(%w(K J), @ss.get_header)    
  end

  def test_rows
    assert_equal(5, @ss.total_rows)
    assert_equal(4, @ss.rows)

    @ss.sheet(0, :skip => 0)
    assert_equal(5, @ss.total_rows)
    assert_equal(5, @ss.rows)

    @ss.sheet(0, :skip => 1)
    assert_equal(5, @ss.total_rows)
    assert_equal(4, @ss.rows)
  end

  def test_validate_no_errors
    validation_errors = @ss.validate do
      column_names :year => 0
      validates :year, :presence => true, :numericality => { :only_integer => false, :greater_than_or_equal_to => 2000, :less_than_or_equal_to => 2100 }
    end
    assert(validation_errors.empty?)
  end


  def test_validate_four_errors
    @ss.sheet(1)
    validation_errors = @ss.validate do
      column_names 0 => :a1, 1 => :a2, 2 => :sum, 3 => :str
      validates :a1, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :a2, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :sum, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :str, :presence => true, :inclusion => { :in => %w(A B D) }
    end
    assert_equal(4, validation_errors.size) 


    # limit the validation errors to 2
    validation_errors = @ss.validate(:max_errors => 2) do
      column_names 0 => :a1, 1 => :a2, 2 => :sum, 3 => :str
      validates :a1, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :a2, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :sum, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :str, :presence => true, :inclusion => { :in => %w(A B D) }
    end
    assert_equal(2, validation_errors.size) 


    # read only 3 rows
    validation_errors = @ss.validate(:max_errors => 0, :row_limit => 3) do
      column_names 0 => :a1, 1 => :a2, 2 => :sum, 3 => :str
      validates :a1, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :a2, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :sum, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 6.0 }
      validates :str, :presence => true, :inclusion => { :in => %w(A B D) }
    end
    assert_equal(3, validation_errors.size) 
  end

  def test_size
    assert_equal(5, @ss.size)
  end

  def test_options_precedence
    assert_equal({:skip=>1, :header_row=>0, :max_errors=>0, :row_limit=>0, :force_nil=>nil}, @ss.options)

    # select "Sheet4" and change option
    @ss.sheet(3, :force_nil => 0.0)
    assert_equal({:skip=>1, :header_row=>0, :max_errors=>0, :row_limit=>0, :force_nil=>0.0}, @ss.options)

    # reselect "Sheet1" and change option
    @ss.sheet(0)
    assert_equal({:skip=>1, :header_row=>0, :max_errors=>0, :row_limit=>0, :force_nil=>nil}, @ss.options)

    # now validate with new options, but the sheet option must be unchanged
    result = @ss.validate(:force_nil => 0.0, :skip => 6) do
      # none
    end
    assert_equal({:skip=>1, :header_row=>0, :max_errors=>0, :row_limit=>0, :force_nil=>nil}, @ss.options)
  end



  def test_read_sheet4
    @ss.sheet(3)

    result = @ss.read(:row_limit => 5) do
      column_names 0 => :qty, 1 => :price, 2 => :tot
      validates :qty, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0 }
      validates :price, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0 }
      validates :tot, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0 }      
    end
    assert_equal([:qty, :price, :tot], result.values.keys)
    assert_equal(3, result.values.size)
    result.values.each do |k, vv|
      assert_equal(5, vv.size)
    end



    result = @ss.read(:force_nil => 0.0) do
      column_names 0 => :qty, 1 => :price, 2 => :tot
      validates :qty, :allow_nil => true, :numericality => { :greater_than_or_equal_to => 0.0 }
      validates :price, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0 }
      validates :tot, :allow_nil => true, :numericality => { :greater_than_or_equal_to => 0.0 }
    end
    assert_equal(3, result.values.size)
    result.values.each do |k, vv|
      assert_equal(6, vv.size)
    end

    result = @ss.read(:force_nil => 0.0, :skip => 6) do
      column_names 0 => :qty, 1 => :price, 2 => :tot
      validates :qty, :allow_nil => true, :numericality => { :greater_than_or_equal_to => 0.0 }
      validates :price, :presence => true, :numericality => { :greater_than_or_equal_to => 0.0 }
      validates :tot, :allow_nil => true, :numericality => { :greater_than_or_equal_to => 0.0 }
    end
    assert_equal(3, result.values.size)
    result.values.each do |k, vv|
      assert_equal(1, vv.size)
    end


  end

  def test_result_formats
    result = @ss.read do
      column_names :a, :b, :c, :d
    end
    y = { 
      :a=>[2012.0, 2012.0, 2012.0, 2013.0], 
      :b=>["F", "F", "G", "F"], 
      :c=>[3.1, 2.5, 0.0, 0.78], 
      :d=>[4.1, 3.5, 1.0, 1.78]
    }
    values_size = y.values.first.size

    assert_equal(y, result.values)
    assert_equal(y, result.values(:columns))

    y = [[2012.0, "F", 3.1, 4.1], [2012.0, "F", 2.5, 3.5], [2012.0, "G", 0.0, 1.0], [2013.0, "F", 0.78, 1.78]]
    assert_equal(y, result.values(:rows_array))

    y = [{:a=>2012.0, :b=>"F", :c=>3.1, :d=>4.1}, {:a=>2012.0, :b=>"F", :c=>2.5, :d=>3.5}, {:a=>2012.0, :b=>"G", :c=>0.0, :d=>1.0}, {:a=>2013.0, :b=>"F", :c=>0.78, :d=>1.78}]
    assert_equal(y, result.values(:rows_hash))
  end

end
