import { slugify } from './slugify';

describe('slugify', () => {
  it.each([
    ['Hello World', 'hello-world'],
    ['NestJS & Python', 'nestjs-python'],
  ])('slugify(%p) -> %p', (input, expected) => {
    expect(slugify(input)).toBe(expected);
  });
});
