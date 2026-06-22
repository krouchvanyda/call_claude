import 'package:erp_mobile/features/finance/data/repositories/accounts_repository.dart';
import 'package:erp_mobile/features/finance/entities/account.dart';
import 'package:test/test.dart';

Account _a(
  String id, {
  String? code,
  String? parent,
  AccountType type = AccountType.asset,
}) =>
    Account(
      id: id,
      code: code ?? id,
      name: id,
      type: type,
      parentId: parent,
    );

void main() {
  group('buildAccountTree', () {
    test('empty input → empty roots (no crash)', () {
      expect(buildAccountTree(const []), isEmpty);
    });

    test('flat list of roots (no parents) → all roots, sorted by code', () {
      final tree = buildAccountTree([
        _a('a-2', code: '2000'),
        _a('a-1', code: '1000'),
        _a('a-3', code: '3000'),
      ]);
      expect(tree.map((n) => n.account.code), ['1000', '2000', '3000']);
      expect(tree.every((n) => n.children.isEmpty), isTrue);
      expect(tree.every((n) => n.depth == 0), isTrue);
    });

    test('depth is computed per level (root = 0)', () {
      final tree = buildAccountTree([
        _a('root', code: '1000'),
        _a('child', code: '1100', parent: 'root'),
        _a('grand', code: '1110', parent: 'child'),
      ]);
      expect(tree, hasLength(1));
      expect(tree.single.depth, 0);
      expect(tree.single.children.single.depth, 1);
      expect(tree.single.children.single.children.single.depth, 2);
    });

    test('children are sorted by code at every level', () {
      final tree = buildAccountTree([
        _a('root', code: '1000'),
        _a('c-c', code: '1300', parent: 'root'),
        _a('c-a', code: '1100', parent: 'root'),
        _a('c-b', code: '1200', parent: 'root'),
      ]);
      expect(
        tree.single.children.map((n) => n.account.code),
        ['1100', '1200', '1300'],
      );
    });

    test(
        'orphan (parentId points at a missing account) is promoted to '
        'root — never silently dropped',
        () {
      final tree = buildAccountTree([
        _a('orphan', code: '9999', parent: 'does-not-exist'),
      ]);
      expect(tree, hasLength(1));
      expect(tree.single.account.id, 'orphan');
      expect(tree.single.depth, 0);
    });

    test('duplicate ids → first-write-wins (no random "latest" picking)',
        () {
      final tree = buildAccountTree([
        _a('dup', code: 'first'),
        _a('dup', code: 'second'),
      ]);
      expect(tree, hasLength(1));
      expect(tree.single.account.code, 'first');
    });

    test('cycle (A→B→A) breaks safely and reports via onCycle', () {
      final reported = <String>[];
      final tree = buildAccountTree(
        [
          _a('a', parent: 'b'),
          _a('b', parent: 'a'),
        ],
        onCycle: reported.add,
      );
      // Both nodes have non-null parents that exist → neither is a root.
      // The walker promotes neither to root because of the parentId bucket;
      // but since both are mutually parented, the dedupe `visited` set
      // breaks the recursion. The result here is intentionally empty —
      // the cycle leaves no usable hierarchy. The important guarantee
      // is "doesn't infinite-loop" + "the cycle is reported".
      expect(tree, isA<List>());
      // At least one cycle event was surfaced.
      // (Both halves of the cycle are valid points to report; the test
      // only asserts the callback was invoked.)
      expect(reported, isNotEmpty);
    });

    test(
        'realistic CoA: roots / mid groups / leaves all wire up correctly',
        () {
      final tree = buildAccountTree([
        _a('1000', code: '1000', type: AccountType.asset),
        _a('1100',
            code: '1100', type: AccountType.asset, parent: '1000'),
        _a('1110',
            code: '1110', type: AccountType.asset, parent: '1100'),
        _a('2000', code: '2000', type: AccountType.liability),
        _a('2100',
            code: '2100',
            type: AccountType.liability,
            parent: '2000'),
      ]);
      expect(tree.map((n) => n.account.code), ['1000', '2000']);
      final assets = tree.first;
      expect(assets.children.map((n) => n.account.code), ['1100']);
      expect(assets.children.first.children.map((n) => n.account.code),
          ['1110']);
      expect(assets.children.first.children.single.isLeaf, isTrue);
      // Depths line up.
      expect(assets.depth, 0);
      expect(assets.children.first.depth, 1);
      expect(assets.children.first.children.first.depth, 2);
    });

    test('isLeaf is true iff children list is empty', () {
      final tree = buildAccountTree([
        _a('parent', code: '1'),
        _a('child', code: '11', parent: 'parent'),
      ]);
      expect(tree.single.isLeaf, isFalse);
      expect(tree.single.children.single.isLeaf, isTrue);
    });
  });
}
