import { SNAKE_CASE_PARAM } from '../schemas/constants.ts';

/** Returns the error shown for a parameter or property name that breaks the snake_case rule. */
export function snakeCaseNameError(name: string, enforceSnakeCase: boolean): string | null {
  if (!enforceSnakeCase || SNAKE_CASE_PARAM.test(name)) return null;
  return `"${name}" must be snake_case (a-z, 0-9, _)`;
}
