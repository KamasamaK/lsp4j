/******************************************************************************
 * Copyright (c) 2018-2019 Microsoft Corporation and others.
 * 
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0,
 * or the Eclipse Distribution License v. 1.0 which is available at
 * http://www.eclipse.org/org/documents/edl-v10.php.
 * 
 * SPDX-License-Identifier: EPL-2.0 OR BSD-3-Clause
 ******************************************************************************/
package org.eclipse.lsp4j.adapters;

import java.util.function.Predicate;

import org.eclipse.lsp4j.PrepareRenameDefaultBehavior;
import org.eclipse.lsp4j.PrepareRenameResult;
import org.eclipse.lsp4j.Range;
import org.eclipse.lsp4j.jsonrpc.json.adapters.EitherTypeAdapter;
import org.eclipse.lsp4j.jsonrpc.json.adapters.EitherTypeAdapter.PropertyChecker;
import org.eclipse.lsp4j.jsonrpc.messages.Either;
import org.eclipse.lsp4j.jsonrpc.messages.Either3;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.TypeAdapter;
import com.google.gson.TypeAdapterFactory;
import com.google.gson.reflect.TypeToken;

public class PrepareRenameResponseAdapter implements TypeAdapterFactory {
	
	private static final TypeToken<Either3<Range, PrepareRenameResult, PrepareRenameDefaultBehavior>> ELEMENT_TYPE
			= new TypeToken<Either3<Range, PrepareRenameResult, PrepareRenameDefaultBehavior>>() {};

	private static final TypeToken<Either<PrepareRenameResult, PrepareRenameDefaultBehavior>> R_ELEMENT_TYPE
			= new TypeToken<Either<PrepareRenameResult, PrepareRenameDefaultBehavior>>() {};

	@SuppressWarnings("unchecked")
	@Override
	public <T> TypeAdapter<T> create(Gson gson, TypeToken<T> type) {
		Predicate<JsonElement> firstChecker = new PropertyChecker("start");
		Predicate<JsonElement> secondChecker = new PropertyChecker("range");
		Predicate<JsonElement> thirdChecker = new PropertyChecker("defaultBehavior");
		return (TypeAdapter<T>) new EitherTypeAdapter<>(gson, ELEMENT_TYPE, firstChecker, secondChecker.or(thirdChecker),
				null, new EitherTypeAdapter<>(gson, R_ELEMENT_TYPE, secondChecker, thirdChecker));
	}
}
