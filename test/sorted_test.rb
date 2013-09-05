require 'test/unit'
require 'ohm/sorted'

class Post < Ohm::Model
  include Ohm::Callbacks
  include Ohm::Sorted

  attribute :order
  attribute :status
  
  sorted :status, by: :order
end

class SortedTest < Test::Unit::TestCase
  def setup
    Ohm.flush
  end

  def test_sorted_find_returns_sorted_set
    Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal Ohm::SortedSet, sorted_set.class
    assert_equal "Post:sorted:status:order:draft", sorted_set.key
  end

  def test_sorted_find_first
    post = Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")

    assert_equal post, sorted_set.first
  end

  def test_sorted_find_order
    post_1 = Post.create(status: "draft", order: 2)
    post_2 = Post.create(status: "draft", order: 3)
    post_3 = Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")

    assert_equal [post_3, post_1, post_2], sorted_set.to_a
  end

  def test_update
    post_1 = Post.create(status: "draft", order: 1)
    post_2 = Post.create(status: "draft", order: 2)

    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [post_1, post_2], sorted_set.to_a

    post_1.update(order: 3)

    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [post_2, post_1], sorted_set.to_a
  end

  def test_delete
    post = Post.create(status: "draft", order: 1)
    post.delete

    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [], sorted_set.to_a
  end

  def test_indexes_nil
    post = Post.create(status: "draft")
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal [post], sorted_set.to_a
  end

  def test_sorted_find_invalid
    exception_class = defined?(Ohm::IndexNotFound) ? Ohm::IndexNotFound : Ohm::Model::IndexNotFound

    Post.create(status: "draft", order: 1)
    assert_raises(exception_class) do
      Post.sorted_find(:foo, status: "draft")
    end

    assert_raises(exception_class) do
      Post.sorted_find(:order, foo: "bar")
    end
  end

  def test_sorted_set_index
    post = Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal post, sorted_set[post.id]
  end

  def test_sorted_set_size
    Post.create(status: "draft", order: 1)
    sorted_set = Post.sorted_find(:order, status: "draft")
    assert_equal 1, sorted_set.size
  end
end
