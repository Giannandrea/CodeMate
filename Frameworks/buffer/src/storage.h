#ifndef BUFFER_H_FCAAENIG
#define BUFFER_H_FCAAENIG

#include <algorithm>
#include <iterator>
#include <memory>
#include <oak/basic_tree.h>
#include <oak/debug.h>
#include <string>
#include <vector>

namespace ng {
    namespace detail {
        struct memory_t
        {
            struct helper_t
            {
                helper_t() = default;

                template <typename _InputIter>
                helper_t(_InputIter first, _InputIter last) : _bytes(first, last)
                {
                    reserve_additional(slack());
                }

                [[nodiscard]] char const* bytes() const noexcept { return _bytes.data(); }
                [[nodiscard]] size_t      size() const noexcept { return _bytes.size(); }
                [[nodiscard]] size_t      available() const noexcept { return _bytes.capacity() - _bytes.size(); }

                template <typename _InputIter>
                void append(_InputIter first, _InputIter last)
                {
                    const auto length = static_cast<size_t>(std::distance(first, last));
                    if (length == 0)
                        return;
                    reserve_additional(length);
                    _bytes.insert(_bytes.end(), first, last);
                }

              private:
                void reserve_additional(size_t additional)
                {
                    const auto required = _bytes.size() + additional;
                    if (required <= _bytes.capacity())
                        return;
                    size_t proposed = std::max(_bytes.capacity() * 2, required + slack());
                    if (proposed < required)
                        proposed = required;
                    _bytes.reserve(proposed);
                }

                [[nodiscard]] static constexpr size_t slack() noexcept { return 16U; }

                std::vector<char>                     _bytes{};
            };

            typedef std::shared_ptr<helper_t> helper_ptr;

            template <typename _InputIter>
            memory_t(_InputIter first, _InputIter last);

            memory_t() = default;
            memory_t(helper_ptr const& helper, size_t offset) : _helper(helper), _offset(offset) {}
            [[nodiscard]] memory_t    subset(size_t from) const { return memory_t(_helper, _offset + from); }
            [[nodiscard]] char const* bytes() const noexcept
            {
                ASSERT(_helper);
                return _helper->bytes() + _offset;
            }
            [[nodiscard]] size_t size() const noexcept
            {
                ASSERT(_helper);
                return _helper->size() - _offset;
            }
            [[nodiscard]] size_t available() const noexcept
            {
                ASSERT(_helper);
                return _helper->available();
            }

            template <typename _InputIter>
            void insert(size_t pos, _InputIter first, _InputIter last);

          private:
            helper_ptr _helper;
            size_t     _offset = 0;
        };

        struct storage_t
        {
            struct value_t
            {
                value_t(memory_t const& memory, size_t size) : _memory(memory), _size(size) {}

                [[nodiscard]] char const* data() const noexcept { return _memory.bytes(); }
                [[nodiscard]] size_t      size() const noexcept { return _size; }

                [[nodiscard]] char const* begin() const noexcept { return data(); }
                [[nodiscard]] char const* end() const noexcept { return data() + size(); }

              private:
                memory_t const& _memory;
                size_t          _size;
            };

            struct iterator
            {
                using iterator_category = std::bidirectional_iterator_tag;
                using value_type        = value_t;
                using difference_type   = std::ptrdiff_t;
                using pointer           = value_t*;
                using reference         = value_t;

                explicit iterator(typename oak::basic_tree_t<size_t, memory_t>::iterator base) : _base(base) {}

                iterator(iterator const& rhs)            = default;
                iterator& operator=(iterator const& rhs) = default;

                bool      operator==(iterator const& rhs) const { return _base == rhs._base; }
                bool      operator!=(iterator const& rhs) const { return _base != rhs._base; }
                iterator& operator--()
                {
                    --_base;
                    return *this;
                }
                iterator& operator++()
                {
                    ++_base;
                    return *this;
                }
                value_t operator*() const { return value_t(_base->value, _base->key); }

              private:
                typename oak::basic_tree_t<size_t, memory_t>::iterator _base;
            };

            storage_t() {}
            storage_t(storage_t const& rhs) { _tree = rhs._tree; }
            storage_t(storage_t&& rhs) { _tree.swap(rhs._tree); }
            storage_t& operator=(storage_t const& rhs)
            {
                _tree = rhs._tree;
                return *this;
            }
            storage_t& operator=(storage_t&& rhs)
            {
                _tree.swap(rhs._tree);
                return *this;
            }

            bool                      operator==(storage_t const& rhs) const;
            bool                      operator!=(storage_t const& rhs) const { return !(*this == rhs); }

            [[nodiscard]] size_t      size() const noexcept { return _tree.aggregated(); }
            [[nodiscard]] bool        empty() const noexcept { return _tree.empty(); }
            void                      swap(storage_t& rhs) { _tree.swap(rhs._tree); }
            void                      clear() { _tree.clear(); }

            [[nodiscard]] iterator    begin() const { return iterator(_tree.begin()); }
            [[nodiscard]] iterator    end() const { return iterator(_tree.end()); }

            void                      insert(size_t pos, char const* data, size_t length);
            void                      erase(size_t first, size_t last);
            char                      operator[](size_t i) const;
            [[nodiscard]] std::string substr(size_t first, size_t last) const;

          private:
            typedef oak::basic_tree_t<size_t, memory_t> tree_t;
            mutable tree_t                              _tree;
            tree_t::iterator                            split_at(tree_t::iterator, size_t pos);
            tree_t::iterator                            find_pos(size_t pos) const;
        };

    } // namespace detail

} // namespace ng

#endif /* end of include guard: BUFFER_H_FCAAENIG */
