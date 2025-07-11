// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Lookup a key from the bucket
fn[T : Eq] Bucket::find(self : Bucket[T], key : T) -> Bool {
  match self {
    JustOne(key1) => key == key1
    More(key1, rest) => if key == key1 { true } else { rest.find(key) }
  }
}

///|
/// Add a new key-value pair to a bucket.
/// Replace the old entry if one with the same key already exists.
fn[T : Eq] Bucket::add(self : Bucket[T], key : T) -> Bucket[T] {
  match self {
    JustOne(key1) => if key == key1 { self } else { More(key, self) }
    More(key1, rest) =>
      if key == key1 {
        self
      } else {
        More(key1, rest.add(key))
      }
  }
}

///|
/// Remove a key from a bucket
fn[T : Eq] Bucket::remove(self : Bucket[T], key : T) -> Bucket[T]? {
  match self {
    JustOne(old_key) => if key == old_key { None } else { Some(self) }
    More(old_key, rest) =>
      if key == old_key {
        Some(rest)
      } else {
        match rest.remove(key) {
          None => Some(JustOne(old_key))
          Some(rest) => Some(More(old_key, rest))
        }
      }
  }
}

///|
/// Get the size of a bucket
fn[T] Bucket::size(self : Bucket[T]) -> Int {
  loop (self, 1) {
    (JustOne(_), acc) => acc
    (More(_, rest), acc) => continue (rest, acc + 1)
  }
}

///|
/// Iterate through elements of a bucket
fn[T] Bucket::each(self : Bucket[T], f : (T) -> Unit raise?) -> Unit raise? {
  loop self {
    JustOne(k) => f(k)
    More(k, rest) => {
      f(k)
      continue rest
    }
  }
}

///|
fn[T] Bucket::iter(self : Bucket[T]) -> Iter[T] {
  Iter::new(f => loop self {
    JustOne(k) => f(k)
    More(k, rest) => if f(k) == IterContinue { continue rest } else { IterEnd }
  })
}

///|
test "Bucket" {
  let b0 : Bucket[_] = JustOne(0)
  inspect((b0.find(0), b0.find(1), b0.size()), content="(true, false, 1)")
  let b1 = b0.add(1)
  inspect((b1.find(0), b1.find(1), b1.size()), content="(true, true, 2)")
  let b2 = b1.add(2)
  inspect((b2.find(0), b2.find(1), b2.size()), content="(true, true, 3)")
  let b3 = b2.remove(0)
  {
    let b1 = b3.unwrap()
    inspect((b1.find(0), b1.find(1)), content="(false, true)")
  }
  let b4 = b2.remove(1)
  let b1 = b4.unwrap() // b4 ? --> return Option instead of Result
  inspect((b1.find(0), b1.find(1)), content="(true, false)")
}

///|
test "Bucket::iter" {
  let b : Bucket[_] = More(0, More(1, JustOne(31)))
  let buf = StringBuilder::new(size_hint=0)
  let mut is_first = true
  b.each(k => {
    if is_first {
      is_first = false
    } else {
      buf.write_string(", ")
    }
    buf.write_string("\{k}")
  })
  inspect(buf.to_string(), content="0, 1, 31")
}

///|
test "Bucket::iter" {
  let b : Bucket[_] = More(0, More(1, JustOne(31)))
  let buf = StringBuilder::new(size_hint=0)
  let mut is_first = true
  b
  .iter()
  .each(k => {
    // weird syntax conventions that
    // braces needed here
    if is_first {
      is_first = false
    } else {
      buf.write_string(", ")
    }
    buf.write_string("\{k}")
  })
  inspect(buf.to_string(), content="0, 1, 31")
}

///|
test "Bucket add and remove" {
  let b0 : Bucket[_] = JustOne(0)
  let b1 = b0.add(1)
  let b2 = b1.add(2)
  let b3 = b2.remove(0).unwrap()
  let b4 = b2.remove(1).unwrap()
  let b5 = b2.remove(2).unwrap()
  assert_eq(b0.find(0), true)
  assert_eq(b0.find(1), false)
  assert_eq(b1.find(0), true)
  assert_eq(b1.find(1), true)
  assert_eq(b2.find(0), true)
  assert_eq(b2.find(1), true)
  assert_eq(b2.find(2), true)
  assert_eq(b3.find(0), false)
  assert_eq(b3.find(1), true)
  assert_eq(b3.find(2), true)
  assert_eq(b4.find(0), true)
  assert_eq(b4.find(1), false)
  assert_eq(b4.find(2), true)
  assert_eq(b5.find(0), true)
  assert_eq(b5.find(1), true)
  assert_eq(b5.find(2), false)
}

///|
test "Bucket size" {
  let b0 : Bucket[_] = JustOne(0)
  let b1 = b0.add(1)
  let b2 = b1.add(2)
  let b3 = b2.remove(0).unwrap()
  let b4 = b2.remove(1).unwrap()
  let b5 = b2.remove(2).unwrap()
  assert_eq(b0.size(), 1)
  assert_eq(b1.size(), 2)
  assert_eq(b2.size(), 3)
  assert_eq(b3.size(), 2)
  assert_eq(b4.size(), 2)
  assert_eq(b5.size(), 2)
}

///|
test "Bucket iter" {
  let b0 : Bucket[_] = JustOne(0)
  let b1 = b0.add(1)
  let b2 = b1.add(2)
  let buf = StringBuilder::new(size_hint=0)
  let mut is_first = true
  b2.each(k => {
    if is_first {
      is_first = false
    } else {
      buf.write_string(", ")
    }
    buf.write_string("\{k}")
  })
  inspect(buf, content="1, 2, 0")
}

///|
test "Bucket iter" {
  let b0 : Bucket[_] = JustOne(0)
  let b1 = b0.add(1)
  let b2 = b1.add(2)
  let buf = StringBuilder::new(size_hint=0)
  let mut is_first = true
  b2
  .iter()
  .each(k => {
    if is_first {
      is_first = false
    } else {
      buf.write_string(", ")
    }
    buf.write_string("\{k}")
  })
  inspect(buf, content="1, 2, 0")
}
