// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  for(
      const                           /// 01: compile-time error
      final                           /// 02: ok
      int x in const [1, 2, 3]) {
    break;
  }
}